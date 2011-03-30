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
* Sort otp.h out - it should not be in this repo
* Get module_xud and module_usb_shared from the right place.

Firmware Overview
=================

This repo contains the hardware design of the XTAG2 and two applications
that run on it: the boot laoder and the debugger.

Known Issues
============

* none

Required Repositories
=====================

* xcommon git\@github.com:xcore/xcommon.git
* sc_jtag git\@github.com:xcore/sc_jtag.git
* xmos_l1_usb_hid  https://www.xmos.com/download/public/USB-Library-and-HID-Example(1.6).zip

The last of the three is not a repo that is controlled under git, but this
should be downloaded from the XMOS website and placed next to the other
repos before doing::

   xmake clean && xmake all

In the proj_xtag2 directory. This should build all.
xmos_l1_usb_hid contains two modules (module_xud and module_usb_shared) that are required.

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the maintainer for this line.
