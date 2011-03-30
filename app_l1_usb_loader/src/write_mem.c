// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

extern int XUD_USB_Done;

void share_serial_number(unsigned char *serial_number, unsigned int length) {
  unsigned char *patchaddr = (unsigned char *)0x1b000;
  int i = 0;

  for (i = 0; i < length; i++) {
    *patchaddr = serial_number[i];
    patchaddr++;
  }
}

void write_mem(unsigned int address, unsigned int size, int *data) {
  int i = 0;
  unsigned int num_words = size >> 2;
  unsigned int *addr_ptr = (unsigned int *)address;

  for (i = 3; i < num_words+3; i++) {
    *addr_ptr = data[i];
    addr_ptr += 1;
  }
}

void jump(void) {
  XUD_USB_Done = 1;
  return;
}

typedef void (*reloc_start)(void);

void _done() {
  reloc_start jump = (reloc_start)0x10000;
  jump();
}
