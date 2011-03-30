// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xclib.h>

#define BUF_WORDS 512  // Buffer length
#define NUM_BUFFERS 16
#define HEADER_SIZE 4

extern unsigned char data_buffer[NUM_BUFFERS][BUF_WORDS];
extern in port UART_RX_PORT;
extern unsigned bit_time;

extern unsigned int do_xlink_reset(unsigned int reset_cmd, chanend reset);

#pragma select handler
void xlink_handler(chanend xlink_data, unsigned int &xlink_ct, unsigned int &xlink_value);

#pragma select handler
inline void xlink_handler(chanend xlink_data, unsigned int &xlink_ct, unsigned int &xlink_value) {
  unsigned int n = testwct(xlink_data);
  switch(n) {
  case 1:
    chkct(xlink_data, 1);
    xlink_ct = 0;
    xlink_value = 0;
    break;
  case 2:
    xlink_value = inuchar(xlink_data);
    xlink_value = xlink_value << 24;
    chkct(xlink_data, 1);
    xlink_ct = 1;
    break;
  case 3:
    xlink_value = inuchar(xlink_data);
    xlink_value = xlink_value << 8 | inuchar(xlink_data);
    xlink_value = xlink_value << 16;
    chkct(xlink_data, 1);
    xlink_ct = 2;
    break;
  case 4:
    xlink_value = inuchar(xlink_data);
    xlink_value = xlink_value << 8 | inuchar(xlink_data);
    xlink_value = xlink_value << 8 | inuchar(xlink_data);
    xlink_value = xlink_value << 8;
    chkct(xlink_data, 1);
    xlink_ct = 3;
    break;
  case 0:
    xlink_value = inuint(xlink_data);
    xlink_ct = 4;
    break;
  }
  xlink_value = byterev(xlink_value);
}


#pragma unsafe arrays
void uart_xc_readAll(chanend from_usb, chanend reset, chanend xlink_data) {
  unsigned data = 0, time;
  unsigned current_val = 1;
  int i, x;
  unsigned char buffer;
  unsigned int xlink_value;
  unsigned int xlink_ct;
  unsigned usb_signal;
  unsigned write_ptr = HEADER_SIZE;
  int buf_num = 0;
  int read_num = 0;
  int count = 0;
  int temp;
  unsigned int device_reset_flag = 1;
  unsigned int device_reset_cmd = 0;

  UART_RX_PORT :> current_val;

  data_buffer[buf_num][2] = count++;
  data_buffer[buf_num][3] = HEADER_SIZE;

  while (1) {
    select {
      case reset :> device_reset_cmd:
        device_reset_flag = do_xlink_reset(device_reset_cmd, reset);
        break;
      case inuint_byref(from_usb, usb_signal):
        if (!usb_signal) {
          return;
        }
        if (buf_num == read_num) {
          (data_buffer, unsigned short [NUM_BUFFERS][BUF_WORDS/2])[buf_num][0] = write_ptr - HEADER_SIZE;
          buf_num = buf_num + 1;
          if (buf_num == NUM_BUFFERS)
            buf_num = 0;
          data_buffer[buf_num][2] = count++;
          data_buffer[buf_num][3] = HEADER_SIZE;
          write_ptr = HEADER_SIZE;
        }
        outuchar(from_usb, read_num);
        read_num = read_num + 1;
        if (read_num == NUM_BUFFERS)
          read_num = 0;
        break;

      case !device_reset_flag => UART_RX_PORT when pinsneq(current_val) :> current_val @ time:
        if ((current_val & 0x1) == 0) { // Only read character if not in uart BREAK
          data = 0;
          time += bit_time + (bit_time >> 1);

          // sample each bit in the middle.
          for (i = 0; i < 8; i++) {
            UART_RX_PORT @ time :> x;
            data = data >> 1 | (x & 1) << 7;
            time += bit_time;
          }

          buffer = data;

          UART_RX_PORT @ time :> current_val;

          if (current_val & 0x1){  // Only return if stop bit seen
            data_buffer[buf_num][write_ptr] = buffer;
            write_ptr++;
            if (write_ptr >= BUF_WORDS-HEADER_SIZE) {
              (data_buffer, unsigned short [NUM_BUFFERS][BUF_WORDS/2])[buf_num][0] = write_ptr - HEADER_SIZE;
              buf_num = buf_num + 1;
              if (buf_num == NUM_BUFFERS)
              buf_num = 0;
              data_buffer[buf_num][2] = count++;
              data_buffer[buf_num][3] = HEADER_SIZE;
              write_ptr = HEADER_SIZE;
            }
          }
        }
        break;
#if 0
      case !device_reset_flag => xlink_handler(xlink_data, xlink_ct, xlink_value):
        if (xlink_ct) {
          if (data_buffer[buf_num][3] == HEADER_SIZE)
            data_buffer[buf_num][3] = write_ptr;
        } else {
          data_buffer[buf_num][write_ptr] = xlink_value;
          //xlink_byte_count++;
          write_ptr++;
          if (write_ptr >= BUF_WORDS-HEADER_SIZE) {
            (data_buffer, unsigned short [NUM_BUFFERS][BUF_WORDS/2])[buf_num][0] = write_ptr - HEADER_SIZE;
            buf_num = buf_num + 1;
            if (buf_num == NUM_BUFFERS)
              buf_num = 0;
            data_buffer[buf_num][2] = count++;
            data_buffer[buf_num][3] = HEADER_SIZE;
            write_ptr = HEADER_SIZE;
          }
        }

      break;
#endif
      case !device_reset_flag => xlink_handler(xlink_data, xlink_ct, xlink_value):
        // Fill in 0, 1, 2, 3 or 4 bytes into buffer.


        for(i = xlink_ct; i != 0; i--) {
          data_buffer[buf_num][write_ptr] = xlink_value;
          xlink_value = xlink_value >> 8;
          //xlink_byte_count++;
          write_ptr++;
          if (write_ptr >= BUF_WORDS-HEADER_SIZE) {
            (data_buffer, unsigned short [NUM_BUFFERS][BUF_WORDS/2])[buf_num][0] = write_ptr - HEADER_SIZE;
            buf_num = buf_num + 1;
            if (buf_num == NUM_BUFFERS)
              buf_num = 0;
            data_buffer[buf_num][2] = count++;
            data_buffer[buf_num][3] = HEADER_SIZE;
            write_ptr = HEADER_SIZE;
          }
        }

        if (xlink_ct != 4) {
          if (data_buffer[buf_num][3] == HEADER_SIZE)
            data_buffer[buf_num][3] = write_ptr;
        }
      break;
    }
  }
}

