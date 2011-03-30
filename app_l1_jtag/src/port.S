// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
.section .dp.bss, "awd", @nobits

.align 4

.globl data_buffer
.globl data_buffer_
data_buffer:
data_buffer_:
  .space 8192

.section .dp.data, "awd", @progbits
.globl UART_RX_PORT
UART_RX_PORT:
  .word XS1_PORT_4E

