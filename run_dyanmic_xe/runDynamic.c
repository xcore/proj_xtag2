// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libusb.h"


#include <string.h>
#include <stdio.h>

// Replace this line with your header generated from an XMOS XE file
#include "app_l1_hid.h"

#define XMOS_VID 0x20b1
#define JTAG_PID 0xf7d1

/* the device's endpoints */

#define EP_IN 0x82
#define EP_OUT 0x01


#define LOADER_BUF_SIZE 512
#define LOADER_CMD_SUCCESS 0
#define LOADER_CMD_FAIL -1

enum loader_cmd_type {
  LOADER_CMD_NONE,
  LOADER_CMD_WRITE_MEM,
  LOADER_CMD_WRITE_MEM_ACK,
  LOADER_CMD_GET_VERSION,
  LOADER_CMD_GET_VERSION_ACK,
  LOADER_CMD_JUMP,
  LOADER_CMD_JUMP_ACK
};

static libusb_device_handle *devh = NULL;

static int dbg_usb_bulk_io(int ep, char *bytes, int size, int timeout) {
    int actual_length;
    int r;
    void *ofunc = signal(SIGINT, SIG_IGN);
    r = libusb_bulk_transfer(devh, ep & 0xff, (unsigned char*)bytes, size, &actual_length, timeout);
    signal(SIGINT, ofunc);
    if (r == 0) {
        return 0;
    }
    if (r == LIBUSB_ERROR_TIMEOUT) {
        //printf("\n***** DEVICE ACCESS TIMEOUT *****\n");
        return -2;
    }
    if (r == LIBUSB_ERROR_NO_DEVICE) {
        return -1;
    }
    return  -3;
}

int device_read(char *data, unsigned int length, unsigned int timeout) {
    int result = 0;
    result = dbg_usb_bulk_io(EP_IN, data, length, timeout);
    return result;
}

int device_write(char *data, unsigned int length, unsigned int timeout) {
    int result = 0;
    result = dbg_usb_bulk_io(EP_OUT, data, length, timeout);
    return result;
}


/*
 * Implement the USB bootloader protocol.
 */
static void burnSerial() {
  unsigned int i = 0;
  unsigned int address = 0;
  unsigned int num_blocks = 0;
  unsigned int block_size = 0;
  unsigned int remainder = 0;
  unsigned int data_ptr = 0;
  int cmd_buf[LOADER_BUF_SIZE/4];
  int bin_len = sizeof(burnData);
  char *charBurnData = (char *)burnData;

  memset(cmd_buf, 0, LOADER_BUF_SIZE);

  address = 0x10000;
  block_size = LOADER_BUF_SIZE - 12;
  num_blocks = bin_len / block_size;
  remainder = bin_len - (num_blocks * block_size);
  printf("Num_blocks: %d\n", num_blocks);

  for (i = 0; i < num_blocks; i++) {
    cmd_buf[0] = LOADER_CMD_WRITE_MEM;
    cmd_buf[1] = address;
    cmd_buf[2] = block_size;
    memcpy(&cmd_buf[3], &charBurnData[data_ptr], block_size);
    device_write((char *)cmd_buf, LOADER_BUF_SIZE, 1000);
    device_read((char *)cmd_buf, 8, 1000);
    address += block_size;
    data_ptr += block_size;
  }

  if (remainder) {
    cmd_buf[0] = LOADER_CMD_WRITE_MEM;
    cmd_buf[1] = address;
    cmd_buf[2] = remainder;
    memcpy(&cmd_buf[3], &charBurnData[data_ptr], remainder);
    device_write((char *)cmd_buf, LOADER_BUF_SIZE, 1000);
    device_read((char *)cmd_buf, 8, 1000);
  }

  printf("Running dynamic USB code...\n");

  cmd_buf[0] = LOADER_CMD_JUMP;
  device_write((char *)cmd_buf, 4, 1000);
  device_read((char *)cmd_buf, 8, 1000);
}



static int find_device(unsigned int id, unsigned int open, char *new) {
    libusb_device *dev;
    libusb_device **devs;
    int i = 0;
    int found = 0;
    char string[18];

    libusb_get_device_list(NULL, &devs);

    while ((dev = devs[i++]) != NULL) {
        struct libusb_device_descriptor desc;
        libusb_get_device_descriptor(dev, &desc);

        if (desc.idVendor != 0x20B1 || desc.idProduct != 0xF7D1) {
            continue;
        }
        if (!open) {
          printf("%d - VID = 0x%x, PID = 0x%x, bcdDevice = 0x%x\n", found, desc.idVendor, desc.idProduct, desc.bcdDevice);
        } else {
            if (found == id) {
              printf("PROGRAM %d - VID = 0x%x, PID = 0x%x, id = %d\n", found, desc.idVendor, desc.idProduct, id);
                if (desc.bcdDevice & 0xff00) {
                  printf("bcdDevice 0x%x\n", desc.bcdDevice);
                    fprintf(stderr, "Device need to be unplugged and plugged back in\n");
                    exit(1);
                }
                if (libusb_open(dev, &devh) < 0) {
                    return -1;
                }
                libusb_get_string_descriptor_ascii(devh, desc.iSerialNumber, string, 17);
                break;
            }
        }
        found++;
    }

    libusb_free_device_list(devs, 1);

    return devh ? 0 : -1;
}

int main(int argc, char **argv) {
    int r = 1;
    int id = 0;
    int list = 0;
    char *startAddr = (char*)&burnData[sizeof(burnData)/sizeof(int) - 9];
    int i;
    if (argc == 2 && strcmp(argv[1], "-l") == 0) {
        list = 1;
    }
    if (argc == 3 && strcmp(argv[1], "-id") == 0) {
      id = atoi(argv[2]);
    }
    r = libusb_init(NULL);
    if (r < 0) {
        fprintf(stderr, "failed to initialise libusb\n");
        return -1;
    }


    if (list) {
        find_device(0,0,"");
    } else {
      printf("looking for device id %d\n", id);
        if (find_device(id,1, startAddr) < 0) {
            fprintf(stderr, "Device not found\n", r);
            return -1;
        }

        r = libusb_claim_interface(devh, 0);
        if (r < 0) {
            fprintf(stderr, "usb_claim_interface error %d\n", r);
            return -1;
        }
        printf("Loading USB Aud \n");
        burnSerial();
        sleep(1);
        printf("Load done...\n");
        libusb_reset_device(devh);
        libusb_close(devh);
    }

    libusb_exit(NULL);

    return 0;
}
