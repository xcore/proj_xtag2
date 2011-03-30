// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <syscall.h>
#include <xs1.h>
#include <xclib.h>
#include <print.h>

#include "xud.h"

#define XUD_EP_COUNT_OUT 2
#define XUD_EP_COUNT_IN 3
#define USB_CORE 0

/* Endpoint type tables */
XUD_EpType epTypeTableOut[XUD_EP_COUNT_OUT] = {XUD_EPTYPE_CTL, XUD_EPTYPE_BUL};
XUD_EpType epTypeTableIn[XUD_EP_COUNT_IN] = {XUD_EPTYPE_CTL, XUD_EPTYPE_DIS, XUD_EPTYPE_BUL};

// Declare ports to remove pull downs
in port pin_3 = XS1_PORT_1L;
in port pin_15 = XS1_PORT_1M;

/* USB Port declarations */
out port p_usb_rst       = XS1_PORT_1I;
clock    clk             = XS1_CLKBLK_3;

void Endpoint0( chanend c_ep0_out, chanend c_ep0_in);

#define BUF_WORDS 256  // Buffer length
int from_host_buf[BUF_WORDS];
int to_host_buf[BUF_WORDS];

#define LOADER_CMD_SUCCESS 0
#define LOADER_CMD_FAIL -1

enum loader_cmd_type {
  LOADER_CMD_WRITE_MEM = 1,
  LOADER_CMD_WRITE_MEM_ACK = 2,
  LOADER_CMD_JUMP = 5,
  LOADER_CMD_JUMP_ACK = 6
};

extern void write_mem(unsigned int address, unsigned int size, int data[]);
extern void jump(void);

int loader_cmd_write_mem(void) {
  unsigned int address = from_host_buf[1];
  unsigned int size = from_host_buf[2];
  int result = LOADER_CMD_SUCCESS;
  unsigned int return_size = 8;
 
  // Call write mem C code
  write_mem(address, size, from_host_buf);

  to_host_buf[0] = LOADER_CMD_WRITE_MEM_ACK;
  to_host_buf[1] = result;

  return return_size;
}

int loader_cmd_jump(void) {
  int result = LOADER_CMD_FAIL;
  unsigned int return_size = 8;

  // Call jump C code
  jump();

  to_host_buf[0] = LOADER_CMD_JUMP_ACK;
  to_host_buf[1] = result;

  return return_size;
}

void loader_thread(chanend from_host, chanend to_host) {
  int loader_thread_done = 0;

  XUD_ep host_out = XUD_Init_Ep(from_host);
  XUD_ep host_in  = XUD_Init_Ep(to_host);

  while (!loader_thread_done) {
    enum loader_cmd_type cmd = 0;
    int datalength = XUD_GetBuffer(host_out, (from_host_buf, char[BUF_WORDS*4]));

    if (datalength != -1) {
      cmd = from_host_buf[0];
      switch (cmd) {
        case LOADER_CMD_WRITE_MEM:
          datalength = loader_cmd_write_mem();
          break;
        case LOADER_CMD_JUMP:
          datalength = loader_cmd_jump();
          loader_thread_done = 1;
          break;
        default:
          datalength = 0;
          break;
      }
      if (datalength > 0) {
          XUD_SetBuffer(host_in, (to_host_buf, char[BUF_WORDS*4]), datalength); 
      }
    }
  }
  XUD_ResetEndpoint(host_out, host_in);
}

#pragma unsafe arrays
void memset(int c[], int v, int x) {
    x >>= 2;
    for(int i = 0; i < x; i++) {
        c[i] = 0;
    }
}

int main()
{
    chan c_ep_out[4], c_ep_in[4];

    par
    {
       {
        timer t;
        unsigned x;
        t :> x;
        t when timerafter(x+10000000) :> void;
        XUD_Manager( c_ep_out, XUD_EP_COUNT_OUT,
                     c_ep_in, XUD_EP_COUNT_IN,
                     null, epTypeTableOut, epTypeTableIn,
                     p_usb_rst, clk, -1, XUD_SPEED_HS, null);  
        }

        /* Endpoint 0 */
        Endpoint0( c_ep_out[0], c_ep_in[0]);
  
        /* Endpoint 1 and 2 */
        loader_thread(c_ep_out[1], c_ep_in[2]);
    }

    return 0;
}








