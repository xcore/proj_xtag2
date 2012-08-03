// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <syscall.h>
#include <platform.h>
#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <stdio.h>

#include "xud.h"
#include "usb.h"

#define CORE_USB 0

#define XUD_EP_COUNT 4

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT] =   {XUD_EPTYPE_CTL, 
                                            XUD_EPTYPE_BUL, 
                                            XUD_EPTYPE_BUL, 
                                            XUD_EPTYPE_DIS};

XUD_EpType epTypeTableIn[XUD_EP_COUNT] = {   XUD_EPTYPE_CTL,
                                             XUD_EPTYPE_DIS, 
                                             XUD_EPTYPE_BUL,
                                             XUD_EPTYPE_BUL};

/* USB Port declarations */
#ifdef G1
on stdcore[CORE_USB] : out port p_usb_rst       = XS1_PORT_1I; // XDK PORT_1B, XTR: 1k, XVB: 1D, XTAG: 1I
#else
on stdcore[CORE_USB] : out port p_usb_rst       = XS1_PORT_1K; // XDK PORT_1B, XTR: 1k
#endif

on stdcore[CORE_USB] : clock    clk             = XS1_CLKBLK_3;

on stdcore[CORE_USB] : clock    uart_clk             = XS1_CLKBLK_4;


on stdcore[CORE_USB] : out port UART_TX_PORT    = XS1_PORT_1J;

//on stdcore[CORE_USB] : in port UART_RX_PORT    = XS1_PORT_1J;
//on stdcore[CORE_USB] : in port UART_RX_PORT    = XS1_PORT_4E;

extern in port UART_RX_PORT;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

#define BUF_WORDS 512  // Buffer length
#define NUM_BUFFERS 16

#define USB_HOST_BUF_WORDS 128

int from_host_buf[USB_HOST_BUF_WORDS];
int to_host_buf[USB_HOST_BUF_WORDS];

extern void dbg_cmd_manager_nochan(int input_size, int input[], int &output_size, int output[], chanend reset);

/////// UART CODE ////////
void uart_xc_readAll(chanend, chanend, chanend);
extern uart_readAll(chanend a, chanend b, chanend c, in port d, unsigned char buffer[NUM_BUFFERS][BUF_WORDS], int x);

unsigned bit_time = 0;
extern unsigned char data_buffer[NUM_BUFFERS][BUF_WORDS];
extern unsigned char data_buffer_[NUM_BUFFERS][BUF_WORDS];

unsigned int xlink_byte_count = 0;

#define ASECOND 100000000
#define HEADER_SIZE 4

extern void progSwitchRegBlind(unsigned int a, unsigned int b, unsigned int c);

static int overrun = 0;

#define XLINK_VAL 0x8000a014
#define XLINK_VAL_HELLO (XLINK_VAL | 0x1000000)

unsigned int do_xlink_reset(unsigned int reset_cmd, chanend reset) {
  unsigned int device_reset_flag = 0;
  timer tmr;
  unsigned s;

  switch (reset_cmd) {
    case 0:
      progSwitchRegBlind(0x82, 0x8000, XLINK_VAL);
      tmr :> s;
      tmr when timerafter(s + 1000) :> void;
      // Clear input buffer once caps have discharged
      progSwitchRegBlind(0x82, 0x8000, XLINK_VAL | 0x800000);

/*
      progSwitchRegBlind(0x82, 0x8000, 00000);
      tmr when timerafter(s + 1000) :> void;
      progSwitchRegBlind(0x82, 0x8000, XLINK_VAL );
*/
      device_reset_flag = 1;
      break;
    case 1:
      progSwitchRegBlind(0x82, 0x8000, XLINK_VAL | 0x800000);
      progSwitchRegBlind(0x82, 0x8000, 0x00000000);
      device_reset_flag = 1;
      break;
    case 2:
      progSwitchRegBlind(0x82, 0x8000, XLINK_VAL_HELLO);
      device_reset_flag = 0;
      break;
    case 0xff:
      // Device restart main loop
      device_reset_flag = 0xff;
      break;
  }

  //reset <: 1;
  outct(reset, 1);

  return device_reset_flag;
}

void uart_thread(chanend from_usb, chanend xlink_data, chanend reset) {
  int character;
  unsigned int usb_signal = 0;
  unsigned char device_reset_cmd = 0;
  unsigned int device_reset_signal = 0;
  bit_time  = XS1_TIMER_MHZ * 1000000 / (unsigned) 115200;

  while (1) {
      // Must wait for reset to be finished
      while (!usb_signal) {
        select {
          case inuint_byref(from_usb, usb_signal):
            break;
          case inuchar_byref(reset, device_reset_cmd):
            chkct(reset, 1);
            device_reset_signal = do_xlink_reset(device_reset_cmd, reset);
            break;
        }
      }

        data_buffer[1][0] = 0;
        outuchar(from_usb, 1);          // acknowledge empty queue

        UART_TX_PORT <: 1;              // Start bit high
        set_port_use_on(UART_RX_PORT);  // And safely open UART port.
        set_port_pull_down(UART_RX_PORT);
        configure_in_port_no_ready(UART_RX_PORT, uart_clk); 
        start_clock(uart_clk);
      
#ifdef XC_MAINLOOP
        uart_xc_readAll(from_usb, reset, xlink_data);
#else
        uart_readAll(from_usb, reset, xlink_data, UART_RX_PORT, data_buffer, bit_time);
#endif

      set_port_use_off(UART_RX_PORT);
  }
}

int from_host_buf_uart[USB_HOST_BUF_WORDS];

#pragma unsafe arrays
void uart_usb_thread(chanend from_host, chanend to_host, chanend to_uart) {
    char cmd = 0;
    int uart_byte_count;
    unsigned char buf_num;
    unsigned started_tx = 0;
    unsigned zero_buf[1]={0xffffffff};

    XUD_ep ep_from_host = XUD_Init_Ep(from_host);
    XUD_ep ep_to_host = XUD_Init_Ep(to_host);

    XUD_GetBuffer(ep_from_host, (from_host_buf_uart, char[USB_HOST_BUF_WORDS*4])); 
    
    while (1) {
        int datalength = 0;
        //if (datalength > 0) {
            if (!started_tx) {
              outuint(to_uart, 1);
              started_tx = 1;
            }
            select {
              case inuchar_byref(to_uart, buf_num):
                for (int i = 0; i < 128; i++) 
                  from_host_buf_uart[i] = (data_buffer_[buf_num], unsigned[])[i];
                outuint(to_uart, 1);
                datalength = XUD_SetBuffer(ep_to_host, (from_host_buf_uart, char[]), USB_HOST_BUF_WORDS*4);            // Send to host
                break;
              default:
                datalength = XUD_SetBuffer(ep_to_host, (zero_buf, char[4]), 4);            // Send to host
                break;
            }
        //}

        if (datalength < 0) {
            XUD_ResetEndpoint(ep_from_host, ep_to_host);
        }
    }
}

void jtag_thread(chanend from_host, chanend to_host, chanend reset) {
  XUD_ep ep_from_host = XUD_Init_Ep(from_host);
  XUD_ep ep_to_host = XUD_Init_Ep(to_host);

  while (1) {
    int datalength = XUD_GetBuffer(ep_from_host, (from_host_buf, char[USB_HOST_BUF_WORDS*4]));
    if (datalength >= 0) {
      //printintln(datalength);
      dbg_cmd_manager_nochan(datalength, from_host_buf, datalength, to_host_buf, reset); 
      datalength = XUD_SetBuffer(ep_to_host, (to_host_buf, char[USB_HOST_BUF_WORDS*4]), datalength);
    }
    if (datalength < 0) {
        XUD_ResetEndpoint(ep_from_host, ep_to_host);
        // Reset UART Thread mainloop
        outuchar(reset, 0xFF);
        outct(reset, 1);
        chkct(reset, 1);
    }
  }
}

int main()
{
    chan c_ep_out[4];
    chan c_ep_in[4];
    chan usb_to_uart;
    chan c;
    chan reset;
  
    par
    {
        on stdcore[CORE_USB] : XUD_Manager( c_ep_out, 4, c_ep_in, 4,
                                            null, epTypeTableOut, epTypeTableIn,
                                            p_usb_rst, clk, -1, XUD_SPEED_HS, null);  
        /* Endpoint 0 */
        on stdcore[CORE_USB] : Endpoint0( c_ep_out[0], c_ep_in[0]);
        on stdcore[CORE_USB] : jtag_thread(c_ep_out[1], c_ep_in[2], reset);
        restOfWorld(c);
        on stdcore[CORE_USB] : uart_thread(usb_to_uart, c, reset);
        on stdcore[CORE_USB] : uart_usb_thread(c_ep_out[2], c_ep_in[3], usb_to_uart);
    }

    return 0;
}








