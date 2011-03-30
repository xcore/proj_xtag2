// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include "otp.h"


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

char serial[] = "XXXXXXXXXXXXXXXX";

int main() {
    timer t;
    unsigned int data[1];
    int i, j;
    unsigned rdata;
    Options opts;

    InitOptions(opts);
    opts.differential_mode = 0;
    for(i = 0 ; i < 4; i++) {
        for(j = 0 ; j < 4; j++) {
            (data,char[4])[j] = serial[i*4+j];
        }
        Program(t, otp_data, otp_addr, otp_ctrl, 2040 + i*2  , data, 1, opts);
        Program(t,otp_data, otp_addr, otp_ctrl, 2040 + i*2+1, data, 1, opts);
    }
    read_sswitch_reg(0, 6, rdata);
    write_sswitch_reg(0, 6, rdata);
    return 0;
}
