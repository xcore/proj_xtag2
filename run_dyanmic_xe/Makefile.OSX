LIBUSB = ../../xmos_libusb_binaries/libusb/Mac

all: runDynamic

runDynamic: runDynamic.c
	gcc -o runDynamic runDynamic.c -L$(LIBUSB) -I$(LIBUSB) -m32 -lusb-1.0


