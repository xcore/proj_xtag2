// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

  .globl fetchchar
  .globl fetchchar.nstackwords
  .linkset fetchchar.nstackwords, 0
  .text
  .align 2
fetchchar:
  int     r1, res[r0]
  chkct   res[r0], XS1_CT_END
  add     r0, r1, 0
  retsp   0

  .globl getend
  .globl getend.nstackwords
  .linkset getend.nstackwords, 0
getend:
  getr    r0, 2
  retsp   0

  /* On entry: r0 - regnum,  r1 - target node,  r2 - value. */
  /* Corrupts r3, r11. Doesn't corrupt param regs. */
  .globl progSwitchRegBlind
  .globl progSwitchRegBlind.nstackwords
  .linkset progSwitchRegBlind.nstackwords, 0
progSwitchRegBlind:
    ldw     r11, dp[ssctrlAddrWord]
    shl     r3, r1, XS1_CHAN_ID_PROCESSOR_SHIFT
    or      r11, r3, r11
    getr    r3, XS1_RES_TYPE_CHANEND
    setd    res[r3], r11
    ldc     r11, XS1_CT_WRITEC
    outct   res[r3], r11

    ldc     r11, XS1_SSWITCH_NODE_ID_NUM
    eq      r11, r11, r0
    bt      r11, retIsValue
    shr     r11, r1, 8
    outt    res[r3], r11
    outt    res[r3], r1
    bu      retSent
retIsValue:
    shr     r11, r2, 8
    outt    res[r3], r11
    outt    res[r3], r2
retSent:

    ldc     r11, 0xff
    outt    res[r3], r11
    shr     r11, r0, 8
    outt    res[r3], r11
    outt    res[r3], r0
    out     res[r3], r2
    outct   res[r3], XS1_CT_END
    freer   res[r3]
    retsp 0

    .section .dp.data,"adw", @progbits
    .align 4
ssctrlAddrWord:
    .word ((XS1_RES_TYPE_CONFIG)<<XS1_RES_ID_TYPE_SHIFT) | ((XS1_CT_SSCTRL)<<XS1_CHAN_ID_CHANNUM_SHIFT)
    .text

