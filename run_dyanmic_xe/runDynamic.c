#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include "usb.h"
#else
#include "libusb.h"
#endif

#include "app_l1_hid.h"

/* the device's vendor and product id */
#define XMOS_XTAG2_VID 0x20b1
#define XMOS_XTAG2_PID 0xf7d1
#define XMOS_XTAG2_EP_IN 0x82
#define XMOS_XTAG2_EP_OUT 0x01

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

#ifdef _WIN32
static usb_dev_handle *devh = NULL;

static int find_xmos_device(unsigned int id) {
  struct usb_bus *bus;
  struct usb_device *dev;
  int found = 0;

  for (bus = usb_get_busses(); bus; bus = bus->next) {
    for (dev = bus->devices; dev; dev = dev->next) {
      if (dev->descriptor.idVendor == XMOS_XTAG2_VID && dev->descriptor.idProduct == XMOS_XTAG2_PID) {
        if (found == id) {
          devh = usb_open(dev);
          break;
        }
      }
    }
  }

  if (!devh)
    return -1;
  
  return 0;
}

static int open_device() {
  int r = 1;
  
  usb_init();
  usb_find_busses(); /* find all busses */
  usb_find_devices(); /* find all connected devices */

  r = find_xmos_device(0);
  if (r < 0) {
    fprintf(stderr, "Could not find/open device\n");
    return -1;
  }
 
  r = usb_set_configuration(devh, 1);
  if (r < 0) {
    fprintf(stderr, "Error setting config 1\n");
    usb_close(devh);
    return -1;
  }

  r = usb_claim_interface(devh, 0);
  if (r < 0) {
    fprintf(stderr, "Error claiming interface %d %d\n", 0, r);
    return -1;
  }

  return 0;
}

static void reset_device() {
  usb_reset(devh);
}

static int close_device() {
  usb_release_interface(devh, 0);
  usb_close(devh);
  return 0;
}

int device_read(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = usb_bulk_read(devh, XMOS_XTAG2_EP_IN, data, length, timeout);
  return result;
}

int device_write(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = usb_bulk_write(devh, XMOS_XTAG2_EP_OUT, data, length, timeout);
  return result;
}

#else 
static libusb_device_handle *devh = NULL;

static int find_xmos_device(unsigned int id) {
  libusb_device *dev;
  libusb_device **devs;
  int i = 0;
  int found = 0;
  
  libusb_get_device_list(NULL, &devs);

  while ((dev = devs[i++]) != NULL) {
    struct libusb_device_descriptor desc;
    libusb_get_device_descriptor(dev, &desc); 
    if (desc.idVendor == XMOS_XTAG2_VID && desc.idProduct == XMOS_XTAG2_PID) {
      if (found == id) {
        if (libusb_open(dev, &devh) < 0) {
          return -1;
        }
        break;
      }
      found++;
    }
  }

  libusb_free_device_list(devs, 1);

  return devh ? 0 : -1;
}

static int open_device() {
  int r = 1;

  r = libusb_init(NULL);
  if (r < 0) {
    fprintf(stderr, "failed to initialise libusb\n");
    return -1;
  }

  r = find_xmos_device(0);
  if (r < 0) {
    fprintf(stderr, "Could not find/open device\n");
    return -1;
  }

  r = libusb_claim_interface(devh, 0);
  if (r < 0) {
    fprintf(stderr, "Error claiming interface %d %d\n", 0, r);
    return -1;
  }

  return 0;
}

static void reset_device() {
  libusb_reset_device(devh);
}

static int close_device() {
  libusb_release_interface(devh, 0);
  libusb_close(devh);
  libusb_exit(NULL);
  return 0;
}

static int device_io(int ep, char *bytes, int size, int timeout) {
  int actual_length;
  int r;
  r = libusb_bulk_transfer(devh, ep & 0xff, (unsigned char*)bytes, size, &actual_length, timeout);

  if (r == 0) {
    return 0;
  } else {
    return 1;
  }
}

static int device_read(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = device_io(XMOS_XTAG2_EP_IN, data, length, timeout);
  return result;
}

static int device_write(char *data, unsigned int length, unsigned int timeout) {
  int result = 0;
  result = device_io(XMOS_XTAG2_EP_OUT, data, length, timeout);
  return result;
}
#endif

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

int main(int argc, char **argv) {
  int i = 0;
  int j = 0;


  if (open_device() < 0) {
    return 1;
  }

  burnSerial();

  reset_device();

  if (close_device() < 0) {
    return 1;
  }

  return 0;
}
