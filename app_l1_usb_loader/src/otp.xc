// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>

#define WRITE_SHIFT 1
#define WRITE  (1 << WRITE_SHIFT)
#define MODE_SEL_SHIFT 8
#define MODE_SEL (1 << MODE_SEL_SHIFT)
#define MR_DIFFERENTIAL_READ_SHIFT 0
#define MR_DIFFERENTIAL_READ (1 << MR_DIFFERENTIAL_READ_SHIFT)

#define MR_ADDRESS 0x8001


#define OTP_DATA_PORT XS1_PORT_32B
#define OTP_ADDR_PORT XS1_PORT_16C
#define OTP_CTRL_PORT XS1_PORT_16D

#define OTPADDRESS 0x7FF
#define OTPMASK    0xFFFFFF
#define OTPREAD 1

/* READ access time */
#define OTP_tACC_TICKS 4 // 40nS

// -------------------------------------------------------------------

port otp_data = OTP_DATA_PORT;
out port otp_addr = OTP_ADDR_PORT;
port otp_ctrl = OTP_CTRL_PORT;

static unsigned otpRead(int address) {
    unsigned value;
    timer t;
    unsigned now;
    
    otp_ctrl <: 0;
    otp_addr <: 0;
    otp_addr <: address;
    sync(otp_addr);
    otp_ctrl <: OTPREAD;
    sync(otp_addr);
    t :> now;
    t when timerafter(now + OTP_tACC_TICKS) :> void;
    otp_data :> value;
    otp_ctrl <: 0;
    return value;
}

extern void fillFromOTP(unsigned char x[40]) {
    int y;
    y = otpRead(2040);
    if (y != 0) {
        otp_ctrl <: MODE_SEL;
        otp_data <: MR_DIFFERENTIAL_READ; sync(otp_data);
        otp_addr <: MR_ADDRESS;           sync(otp_addr);
        otp_ctrl <: MODE_SEL | WRITE;
        otp_ctrl <: MODE_SEL;
        otp_ctrl <: 0;
        (x,unsigned int[4])[0] = otpRead(2040);
        (x,unsigned int[4])[1] = otpRead(2042);
        (x,unsigned int[4])[2] = otpRead(2044);
        (x,unsigned int[4])[3] = otpRead(2046);
    } else {
        (x,unsigned int[4])[0] = 
            (x,unsigned int[4])[1] =
            (x,unsigned int[4])[2] = 
            (x,unsigned int[4])[3] = 0x58585858;
    }
}
