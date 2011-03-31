USB debugger description and standards
......................................

Introduction
============

This document explains how the XMOS toolchain uses an XS1-L1 in order to
debug systems that are built out of one or more XCores. It explains how an
XTAG2 works, and how the XTAG2 port layout, schematics, and software can be
used to build XTAG2s that may be embedded in other systems. It uses the
bootloader described in ``{\em USB boot loader description and standards}''
in order to download the firmware.

This document specifies a set of the standards that must be followed for a
debugger design to be compatible with the XMOS toolchain. These standards are:

*USB-DEBUG-1: USB enumeration.*
  This details the USB descriptors to use
  when enumerating as a bootloader.

*USB-DEBUG-2: Hardware design.*
  This details the schematics to use when
  designing a bootloader.

*USB-DEBUG-3: USB debug protocol.*
  This details the
  protocol to use over the two USB endpoints.

*USB-DEBUG-4: USB debug serial number assignment.*
  This details the meaning
  of serial numbers.

The use of the XMOS USB Vendor ID and the allocated PID are allowed
provided that these standards are followed.

A block diagram of an XTAG2 is shown in Figure~\ref{figure:block-layout}.
It comprises a USB-PHY, an L1 that is used by the debugger (it runs the USB
to debugger firmware) connected to one L1 that is being debugged. The XTAG2 has a single
L1 and a 20 way connector that can connect it to any other board that
carries an L1 (or other XCore processor). Embedded XTAG2s (found on, for
example, the XK-XMP-64) do not have a 20-way connector, but use the same
schematics otherwise.

An XTAG2 works as follows:

#. An XTAG2 contains an L1 that is booted from OTP, the boot program
   is a USB boot loader, a program that enumerates on the USB bus and
   presents itself as a device that accepts programs to execute.
#. xgdb will scan the USB bus and try and find devices that are both a boot
   loader (determined by the VID, PID and version number of the device),
   and that have a serial number that indicates that this device is debugger
   compatible.
#. xgdb will load the debugger firmware onto all devices that are bootloaders
   and debugger compatible. Each device
   that receives the bootcode will copy its serial number to the 16 bytes
   at address 0x1B000 to 0x1B00F prior to executing the new code.
#. The debugger firmware will on boot pick up the serial number to use
   from address 0x1B000, and then enumerate as a device with that serial
   number.
#. xgdb uses a protocol over USB to talk to the debugger firmware that allows the JTAG
   chain to be scanned, that enables memory read/write on specific cores,
   and register read/writes on specific threads. xgdb uses the debugger
   firmware for remote
   debugging of applications.

\begin{figure}
\begin{center}\includegraphics[width=\textwidth]{../images/block-layout.pdf}\end{center}
\caption{Block diagram of debugging over USB}\label{figure:block-layout}
\end{figure}

PID and VID
-----------

USB uses a Product Identifier (PID) and Vendor Identifier (VID)
to indicate the product and vendor. The debugger firmware uses the PID and
VID used by the bootloader, in order to avoid
windows requiring multiple driver installations. The values of PID and VID
are specified in Standard USB-DEBUG-1, in ``{\em USB boot loader description and standards}''.

Version numbers
---------------

The version number is used to differentiate between bootloader (major
version 0) and debugger firmware (major version not equal to 10). This method is
used since Windows will not require a new driver for a different version.

Serial numbers
--------------

The serial number must uniquely identify the hardware. The same serial
number must be used for both the bootloader and the debugger firmware (again in
order to avoid windows requiring multiple drivers). The serial number is
used to decide what capabilities this device has, and must adhere to the
specification in Standard USB-DEBUG-4 below. 

Standard USB-DEBUG-1: USB enumeration details
=============================================

The descriptor that is used should contain a device class, subclass and
protocol of all 0xff, and have one configuration. The device qualifier
should indicate a max packet size of 64 bytes.

The single interface should have two endpoints, interfaceclass, subclass
and protocol should all be 0xff. For each endpoint the mac packet size
should be set to 512, and the interval should be set to 1.

Any debugger over USB converter must enumerate using the following details:

* It must use VID (Vendor ID) 0x20B1.
* It must use PID (Product ID) 0xF7D1.
* It must enumerate with major version number equal to 10.
* It must enumerate with a serial number identical to that of the
  bootloader; it must read this from address 0x1B000
* It must have a serial number starting with 'D' or 'd', and it must
  have the appropriate bits set to indicate how the debugger works (see
  Standard USB-DEBUG-4 below).

Debugger firmware must not be programmed in flash or OTP of an L1, and must always be
uploaded by the debugger. This ensures that firmware can be upgraded at any
time.

Standard USB-DEBUG-2: XTAG2 design
==================================

Clock frequencies
-----------------

When building an XTAG2 the XTAG2 must run at 400 Mhz derived from a 13 Mhz
Crystal.

Port map
--------

The L1 on the XTAG2 must use the following portmap together with the portmap
specified in ``{\em USB boot loader description and standards}''. All pins labelled TARGET should be
connected to the device to be debugged. Series resistors may be required,
and one is strongly encouraged to use the `XTAG2 design <../../hw>`_
verbatim.


=====  ======  ======  =======  ================
 Pin            Port                 Signal 
-----  -----------------------  ----------------
       1bit    4bit    8bit                     
=====  ======  ======  =======  ================
X0D0   P1A0                     TARGET_TDO
X0D1   P1B0                     TARGET_TDI
X0D4           P4B0             TARGET_XLINK_TO_TARGET_1
X0D5           P4B1             TARGET_XLINK_TO_TARGET_0
X0D6           P4B2             TARGET_XLINK_FROM_TARGET_0
X0D7           P4B3             TARGET_XLINK_FROM_TARGET_1
X0D10  P1C0                     TARGET_TMS
X0D11  P1D0                     TARGET_TCK
X0D25  P1J0                     TARGET_UART_TO_TARGET
X0D26          P4E0             TARGET_UART_FROM_TARGET
X0D34  P1K0                     TARGET_DBG
X0D35  P1L0                     TARGET_TRST_N
X0D36  P1M0                     TARGET_RST_N
=====  ======  ======  =======  ================


The UART and XLINK connections are optional (refer to Standard USB-DEBUG-4
for which serial number to use).

Pin out
-------

If a 20-pin female IDC connector is used to connect the XTAG2 to the hardware to
be debugged, then the layout should be as follows:

====  ===========================
Pin   Signal  
====  ===========================
1     5V (optional, NC otherwise) 
3     TRST_N 
4     GND
5     TDO (output by the target) 
6     XLINK_FROM_TARGET_1 
7     TMS 
8     GND
9     TCK 
10    XLINK_FROM_TARGET_0 
11    DBG
12    GND
13    TDI (input to the target) 
14    XLINK_TO_TARGET_0 
15    RESET_N
16    GND
17    UART  (to the target) 
18    XLINK_TO_TARGET_1 
19    UART  (to the target) 
20    GND 
====  ===========================


Standard USB-DEBUG-3: USB debug protocol
========================================

The protocol of the debugger over USB firmware requires four endpoints (in
addition to endpoint 0) that are used as described below. Communication is
synchronous, that is, for every OUT request the host must issue an IN
request to verify that the operation has completed. This applies to the two
debug endpoints (0x01, 0x82) and the two serial endpoints (0x02, 0x83).

The protocol over the endpoints for version 2 (minor version number of the
USB device) is described below. If a debugger detects a device with a minor
version number different from 2, then it can send a
``DBG\_CMD\_FIRMWARE\_REBOOT'' in order to update the device with
compatible firmware. This will upgrade or downgrade firmware as
appropriate.

Debug Out Endpoint 1 (0x01)
---------------------------

All commands comprise a 124 word block of data, of which the first word is
the command, and the subsequent 123 words carry a payload. Each command is
listed below:

*DBG_CMD_CONNECT_REQ --- 1*
  This requests the adapter to connect to the device(s). It carries the
  following payload:

  * 1:jtagSpeed. The speed at which to connect to the device.
    Device dependent (Should be defined!)
  * 2:debugEnabled. ?
  * 3:jtagDevsPre. the number of devices in the chain to ignore
    (used for JTAG debugging only, and only when the board contains
    other devices that are not to be debugged, eg, an FPGA)
  * 4:jtagBitsPre. the number of bits in the chain to ignore
    (used for JTAG debugging only, and only when the board contains
    other devices that are not to be debugged, eg, an FPGA)
  * 5:jtagDevsPost. ?
  * 6:jtagBitsPost. ?
  * 7:jtagMaxSpeed. ?

  The adapter shall return a DBG_CMD_CONNECT_ACK, see below.

*DBG_CMD_DISCONNECT_REQ --- 3*
  Requests disconnection from the current device - no parameters
  required. 
  The adapter shall return a DBG_CMD_DISCONNECT_ACK, see below.

*DBG_CMD_GET_CORE_STATE_REQ --- 5*

*DBG_CMD_ENABLE_THREAD_REQ --- 7*

*DBG_CMD_DISABLE_THREAD_REQ --- 9*

*DBG_CMD_READ_REGS_REQ --- 11*

*DBG_CMD_WRITE_REGS_REQ --- 13*

*DBG_CMD_READ_MEM_REQ --- 100*

*DBG_CMD_WRITE_MEM_REQ --- 102*

*DBG_CMD_READ_OBJ_REQ --- 104*

*DBG_CMD_STEP_REQ --- 106*

*DBG_CMD_CONTINUE_REQ --- 108*

*DBG_CMD_ADD_BREAK_REQ --- 110*

*DBG_CMD_REMOVE_BREAK_REQ --- 112*

*DBG_CMD_GET_STATUS_REQ --- 114*

*DBG_CMD_INTERRUPT_REQ --- 116*

*DBG_CMD_RESET_REQ --- 118*

*DBG_CMD_FIRMWARE_REBOOT --- 0x060210ad*
  This command is ignored. No payload is required.

Debug In Endpoint 2 (0x82)
--------------------------

*DBG_CMD_CONNECT_ACK --- 2*
  This command carries a payload as follows:

  * 1: numChips. a word indicating the number of chips, 
  * 2..n+1: chipType. one word for each chip indicating the type
    of the chip.
  * n+2..2n+1: numCores. one word for each chip indicating the
    number of cores on this chip.
  * 2n+2..3n+1: numThreads. one word for each chip indicating the
    number of threads on each core on this chip.
  * 3n+2..4n+1: numThreads. one word for each chip indicating the
    number of regisetrs for each thread on each core on this chip.

  If more than 31 chips are present, multiple INs should be requested
  and answered.

*DBG_CMD_DISCONNECT_ACK --- 4*

*DBG_CMD_GET_CORE_STATE_ACK --- 6*

*DBG_CMD_ENABLE_THREAD_ACK --- 8*

*DBG_CMD_DISABLE_THREAD_ACK --- 10*

*DBG_CMD_READ_REGS_ACK --- 12*

*DBG_CMD_WRITE_REGS_ACK --- 14*

*DBG_CMD_READ_MEM_ACK --- 101*

*DBG_CMD_WRITE_MEM_ACK --- 103*

*DBG_CMD_READ_OBJ_ACK --- 105*

*DBG_CMD_STEP_ACK --- 107*

*DBG_CMD_CONTINUE_ACK --- 109*

*DBG_CMD_ADD_BREAK_ACK --- 111*

*DBG_CMD_REMOVE_BREAK_ACK --- 113*

*DBG_CMD_GET_STATUS_ACK --- 115*

*DBG_CMD_INTERRUPT_ACK --- 117*

*DBG_CMD_RESET_ACK --- 119*

*DBG_CMD_FIRMWARE_REBOOT_ACK --- 0x160210ad*



Serial Out Endpoint 2 (0x02)
----------------------------

The host can at any time request input from the UART by supplying data on
this channel. If any bytes are present in a packet, these packets may be
posted on the serial link (UART or XLINK). Note - output not implemented at
present.

Serial In Endpoint 3 (0x83)
---------------------------

After a Serial out, the host shall do a serial IN where data is supplied to
the host. The first byte carries the length information, packets are always
256 bytes long (carrying at most 255 characters of serial information).

Standard USB-DEBUG-4: USB debug serial number assignment
========================================================

The serial number of a debug device not developed by XMOS shall start with
a 'D' or a 'd'. The subsequent two characters indicate the
debugging capabilities of this device.
\begin{itemize}
  \item
    Each of those two characters will be in the range ``0-9'',
    ``A-Z'', ``a-z'',  ``\_'', and ``.'' encoding a 6-bit number. 
  \item
    The least significant bit (Bit 0) indicates that this device has a UART. 
%  \item
 %   Bit 1 indicates that an XLink is connected
 \item
    Bit 2 indicates that this device is JTAG
    compatible (the hardware follows standard USB-DEBUG-3, above), and that the debugger can use
    this device to upload JTAG code to.
  \item
    Bit 3 indicates that the first core on the JTAG chain should be skipped.
  \item
    Bits 1 and 4-11 are reserved.
\end{itemize}
Only JTAG with optional UART is supported at present; which are the
values D04 and D05.

All debug strings will have a 13 character user-defined identifier afterwards.
If the 13 characters user defined ID start with an 'r' or an 'R'
then the remaining 12 characters are a 72-bit random string encoded
using the character set specified earlier.
