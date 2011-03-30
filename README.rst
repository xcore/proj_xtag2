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

This repo contains the hardware design of the XTAG2 and the applications
that run on it: the boot loader, the debugger, and a program to burn the serial number.

app_l1_usb_boot_loader is stored in the OTP of an XTAG2 (or in flash if flash is present).
If stored in OTP it has to fit in 8K - this can be a squeeze depending on the version of the XUD library.
When executing this program will enumerate and wait for firmware to be downloaded to the XTAG2.

app_l1_jtag is the default firmware for an XTAG2, and it implements a program that interfaces GDB to a system over JTAG.
After compilation it is bundled with GDB and GDB will load it into any uninitialised XTAG2, and then query all connected XTAG2s
for the elements on their JTAG scan chains.

app_l1_otp_programmer is a small program that can be downloaded onto the XTAG2 instead of app_l1_jtag, and it will program a serial number
into the XTAG2. Be careful, unless the program is changed the number will be all Xs.

Known Issues
============

* none

Required Repositories
=====================

* xcommon git\@github.com:xcore/xcommon.git
* sc_jtag git\@github.com:xcore/sc_jtag.git
* xmos_l1_usb_hid  https://www.xmos.com/download/public/USB-Library-and-HID-Example(1.6).zip

The first two are repos on github that should be installed beside the directory holding this repo.
The third item is not a repo that is controlled under git. This directory should be downloaded from
the XMOS website and placed besides the other repos. Then enter the proj_xtag2 directory and execute::

   xmake clean && xmake all

This should build all three apps.
xmos_l1_usb_hid contains two modules (module_xud and module_usb_shared) that are required. The direcotry structure should hence be::

  ...
  proj_xtag2/
    app_l1_jtag
    app_l1_otp_programmer/
    ...
  sc_jtag/
    module_jtag_master/
    module_xcore_debug/
    ...
  xmos_l1_usb_hid/
    module_xud/
    module_usb_shared/
    ...
  xcommon/
    ...
  ...
Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the maintainer for this line.
