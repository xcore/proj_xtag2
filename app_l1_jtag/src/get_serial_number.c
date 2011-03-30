// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

void get_serial_number(unsigned char *serial_number, unsigned int length) {
  unsigned char *patchaddr = (unsigned char *)0x1b000;
  int i = 0;

  for (i = 0; i < length; i++) {
    *serial_number = *patchaddr;
    serial_number++;
    patchaddr++;
  }
}
