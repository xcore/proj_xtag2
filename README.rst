XTAG2
.....

:Stable release:  unreleased

:Status:  Feature complete

:Maintainer:  https://github.com/mattfyles, https://github.com/xmos-corin

:Description:  XTAG2 software


Key Features
============

* XTAG2 hardware design
* XTAG2 bootloader
* XTAG2 firmware for gdb

To Do
=====

* Test
* Make otp programmer work and put it in Makefile
* Factor out XTAG2.xn into module_xtag2

Firmware Overview
=================

This repo contains the hardware design of the XTAG2 and two applications
that run on it: the boot laoder and the debugger.

Known Issues
============

* OTP needs otp.h and libotp

Required Repositories
================

* module_xud  https://www.xmos.com/download/public/USB-Library-and-HID-Example(1.6).zip
* xcommon git\@github.com:xcore/xcommon.git
* sc_jtag git\@github.com:xcore/sc_jtag.git

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the maintainer for this line.
