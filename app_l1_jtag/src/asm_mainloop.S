// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#define BUF_WORDS 128  // Buffer length
#define NUM_BUFFERS_BITS 4
#define HEADER_SIZE 4

#define STACK_SIZE  0x10

.cc_top uart_readAll.function,uart_readAll
.align    4
.globl uart_readAll
.globl uart_readAll.nstackwords
.globl uart_readAll.maxthreads
.globl uart_readAll.maxtimers
.globl uart_readAll.maxchanends
.globl uart_readAll.maxsync
.linkset uart_readAll.locnoside, 0
.linkset uart_readAll.locnochandec, 1
.linkset .LLNK1, do_xlink_reset.nstackwords $M do_xlink_reset.nstackwords
.linkset .LLNK0, .LLNK1 + STACK_SIZE
.linkset uart_readAll.nstackwords, .LLNK0
#define readnum     0x8
#define first       0x9
#define fromUsb     0xa
#define uartPort    0xb
#define count       0xc
#define buf_num     0xd
#define reset       0xe
#define tmp         0xf
    
#define data_buffer (STACK_SIZE+1)
#define bit_time    (STACK_SIZE+2)


uart_readAll:
    entsp     STACK_SIZE
    stw       r4, sp[0x1] 
    stw       r5, sp[0x2] 
    stw       r6, sp[0x3] 
    stw       r7, sp[0x4] 
    stw       r8, sp[0x5] 
    stw       r9, sp[0x6] 
    stw       r10, sp[0x7] 
    
    stw       r0, sp[fromUsb]
    stw       r1, sp[reset]
    stw       r3, sp[uartPort]
    add       r5, r2, 0

startover:
    ldc       r8, HEADER_SIZE/4
    ldw       r10, sp[data_buffer]
    ldc       r4, BUF_WORDS
// R0: scratch
// R1: reset
// R2: scratch
// R3: scratch
// R4: writePtrLimit
// R5: xlinkData
// R6: scratch
// R7: current_data_word
// R8: writePtr
// R9: byteIndex
// R10: bufferPointer
// R11: scratch

    ldc       r0, 0
    stw       r0, sp[readnum]
    stw       r0, sp[count]
    stw       r0, sp[buf_num]
    
    ldw       r0, sp[reset]
    eeu       res[r0]            // Set up reset channel vector
    ldap      r11, resetChannel
    setv      res[r0], r11
    setc      res[r0], XS1_SETC_IE_MODE_INTERRUPT

    ldw       r0, sp[fromUsb]
    eeu       res[r0]            // Set up usb channel vector
    ldap      r11, usbChannel
    setv      res[r0], r11

    ldw       r0, sp[uartPort]
    ldap      r11, uart  // Set up UART - do not yet enable
    setv      res[r0], r11
    setc      res[r0], XS1_SETC_COND_NONE
    in        r11, res[r0]
    setc      res[r0], XS1_SETC_COND_NEQ
    setd      res[r0], r11

    ldap      r11, xlinkChannel // Set up xlink - do not yet enable. Wait for reset
    setv      res[r5], r11

    bl        initDataBuffer
    ldc       r9, 0               // Reset byte count
    ldc       r7, 0               // Reset final word
    ldc       r1, 1
    
    setsr     2
    waiteu


resetChannel:                     // Input word from channel, pass it to reset
    clrsr   0x1a                                // Clear InInterrupt bit (and InKernel)

    stw    r1, sp[tmp]
    ldw    r1, sp[reset]
    int    r0, res[r1]    
    chkct  res[r1], 1
    bl     do_xlink_reset
    ldc    r1, 0xff               // Check for mainloop exit
    eq     r6, r0, r1
    bt     r6, return             // Return from main loop
    ldw    r1, sp[tmp]
    ldw    r6, sp[uartPort]     
    eef    r0, res[r6]            // Result from reset guards cases for Uart/xlink
    eef    r0, res[r5]
    ldap   r11, xlinkDiscard
    setv   res[r5], r11
    bu     startover

usbChannel:
    ldw    r3, sp[fromUsb]        // Usb wants a packet - or signsals reenumeration
    in     r0, res[r3]            // Get command word
    ldw    r2, sp[readnum]        // Find which buffer number to transmit next
    ldw    r11, sp[buf_num]
    eq     r0, r11, r2            // If this is the buffer we are writing into, we need to close
    bf     r0, bufferComplete     // the current buffer
    stw    r7, r10[r8]            // store final word
    bl     advanceBuffer          //    --> Close current buffer, start with new buffer
    ldc    r9, 0                  // And reset bytecount to 0.
    ldc    r7, 0                  // reset final word
    ldc    r1, 1
bufferComplete:
    outt   res[r3], r2            // Output the current buffer to the usb layer
    add    r2, r2, 1              // And advance the buffer number by 1.
    zext   r2, NUM_BUFFERS_BITS   // Modulo 2^NUM_BUFFER_BITS
    stw    r2, sp[readnum]        // And store the read number.
    waiteu

uart:
    ldw    r6, sp[uartPort]
    getts  r3, res[r6]            // Get the time that the start bit arrived
    in     r11, res[r6]
    setd   res[r6], r11           // Reset the neq condition data
    zext   r11, 1                 // Inspect bit to be a start bit (and not end of break)
    waitet r11
    setc   res[r6], XS1_SETC_COND_NONE  // No longer conditional - get all bits
    ldc    r0, 0                  // Received byte
    ldw    r11,sp[bit_time]       // Add 1.5 bit times to start bit
    add    r3, r3, r11
    shr    r11, r11, 1
    add    r3, r3, r11
    ldc    r2, 8                  // number of bits to receive
bitLoop:    
    setpt  res[r6], r3            // Wait for next bit - in middle of bit
    in     r11, res[r6]
    zext   r11, 1                 // extract bit 1 of 4-bit port
    shl    r0, r0, 1              // Or into received word
    or     r0, r0, r11
    ldw    r11,sp[bit_time]       // Increment time to point to middle of next bit
    add    r3, r3, r11
    sub    r2, r2, 1
    bt     r2, bitLoop            // branch if counter -1 is not zero

    setpt  res[r6], r3            // Wait for stop bit
    in     r11, res[r6]           
    setc   res[r6], XS1_SETC_COND_NEQ // Back to conditional waits
    setd   res[r6], r11           // On this last data word
    zext   r11, 1                 // Check that stop bit is zero
    waitef r11
    shl    r0, r0, 24             // Put received bits in the right order
    bitrev r0, r0
    ldc    r2, 1                  // And record that we have received one byte.
    bu     gotData


xlinkDiscard:
    testct  r0, res[r5]           // Discarding, check whether we are trying to dispose a CT
    bf      r0, discardToken      // Ordinary tokens are just discarded
    inct    r0, res[r5]           // Control tokens are compared against the magic number
    ldc     r11, 0x55             // 0x55 indicates a start of valid data
    eq      r0, r0, r11
    waitef  r0                    // if invalid, keep discarding
    ldap    r11, xlinkChannel     // if valid, rerouted events.
    setv    res[r5], r11
    waiteu
discardToken:
    int     r0, res[r5]
    waiteu

    
xlinkChannel:
    testwct r0, res[r5]     // Fetch all tokens til control token
    bru     r0
    bu      case0
    bu      case1
    bu      case2
    bu      case3
    bu      case4

case0:                     // four data tokens
    in      r0, res[r5]
    byterev r0, r0
    ldc     r6, 0
    maccu   r6, r7, r1, r0
    stw     r7, r10[r8]                // Store this word
    or      r7, r6, r6
    add     r8, r8, 1                  // adjust word pointer
    eq      r0, r8, r4                 // and check that we are not in the next buffer
    waitef  r0
    bl      advanceBufferFull
    waiteu

case1:                      // No data tokens, but a control token
    inct    r3, res[r5]
    eq      r3, r3, 1
    waitef  r3
    bu      controlTokenOnly

case2:                      // One data token
    int     r0, res[r5]
    shl     r0, r0, 24
    ldc     r2, 1
    bu      gotXlinkData

case3:                      // Two data tokens 
    int     r0, res[r5]
    int     r2, res[r5]
    shl     r0, r0, 8
    or      r0, r0, r2
    shl     r0, r0, 16
    ldc     r2, 2
    bu      gotXlinkData

case4:                     // Three data tokens
    int     r0, res[r5]
    int     r2, res[r5]
    shl     r0, r0, 8
    or      r0, r0, r2
    int     r2, res[r5]
    shl     r0, r0, 8
    or      r0, r0, r2
    shl     r0, r0, 8
    ldc     r2, 3

gotXlinkData:
    inct    r3, res[r5]              // We must now get a control token
    eq      r3, r3, 1                // If not END_CT discard all data.
    waitef  r3                      
    byterev r0, r0
gotData:
    ldc     r6, 0
    maccu   r6, r7, r1, r0
    add     r9, r9, r2
    shr     r0, r9, 2
    bf      r0, oneWordOnly            // Did not advance over a word boundary
    stw     r7, r10[r8]                // Store this word
    or      r7, r6, r6
    zext    r9, 2                      // Compute byte index mod 4.
    add     r8, r8, 1                  // adjust word pointer
    eq      r0, r8, r4                 // and check that we are not in the next buffer
    bf      r0, noBufferAdvance
    bl      advanceBufferFull
noBufferAdvance:    
oneWordOnly:
    shl     r11, r9, 3
    ldc     r1, 1
    shl     r1, r1, r11
controlTokenOnly:   
    ldw     r2, sp[first]              // Check if first is filled in
    waitet  r2                         // if so, wait
    shl     r11, r8, 2                 // fill in first
    add     r11, r11, r9               // Compute byte index from word and byte index
    stw     r11, sp[first]
    waiteu
          
return:
    ldw       r0, sp[uartPort]
    setc      res[r0], XS1_SETC_COND_NONE
    ldw       r0, sp[reset]
    setc      res[r0], XS1_SETC_IE_MODE_EVENT    // Set IE mode back to events
    clre                                        // Clear all events
    ldw       r4, sp[0x1] 
    ldw       r5, sp[0x2] 
    ldw       r6, sp[0x3] 
    ldw       r7, sp[0x4] 
    ldw       r8, sp[0x5] 
    ldw       r9, sp[0x6] 
    ldw       r10, sp[0x7] 
    retsp     0x10 

advanceBuffer:
    shl     r11, r8, 2         
    add     r11, r11, r9                // Compute length in bytes
    sub     r11, r11, HEADER_SIZE
    bu      advEither
advanceBufferFull:
    ldc     r11, (BUF_WORDS*4)-HEADER_SIZE            // Buffer is full.
advEither:
    ldw     r0, sp[first]               // Location of first valid entry
    shl     r0, r0, 24                // Shift to bits [31..24]
    or      r11, r11, r0                // Or into first word
    ldw     r0, sp[count]               // Serial number
    add     r0, r0, 1                   // Increment serial number
    zext    r0, 8
    stw     r0, sp[count]
    shl     r0, r0, 16                   // Shift serial number to bits [23..16]
    or      r11, r11, r0                // Or into first word
    stw     r11, r10[0]                 // And store first word of buffer
    ldw     r0, sp[buf_num]
    add     r0, r0, 1                   // Increment buffer number
    zext    r0, NUM_BUFFERS_BITS        // Modulo 2^NUM_BUFFER_BITS

    add     r11, r0, 1                   // Increment buffer number
    zext    r11, NUM_BUFFERS_BITS        // Modulo 2^NUM_BUFFER_BITS
    ldw     r10, sp[readnum]
    eq      r10, r10, r11
    bf      r10, notDestroyingUsb
    or      r0, r11, r11
notDestroyingUsb:   
    stw     r0, sp[buf_num]
    mul     r11, r4, r0                 // Compute start of array in words
    ldw     r10, sp[data_buffer]        // Relative to data_buffer
    ldaw    r10, r10[r11]
initDataBuffer: 
    ldc     r0, 0
    stw     r0, sp[first]
    ldc     r8, HEADER_SIZE/4
    retsp   0

    
.cc_bottom uart_readAll.function
.linkset uart_readAll.maxchanends, do_xlink_reset.maxchanends
.linkset uart_readAll.maxtimers, do_xlink_reset.maxtimers
