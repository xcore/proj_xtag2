LIBUSB = ../../xmos_libusb_binaries/libusb/Mac

all: burnSerial hello.xe

burnSerial: burnSerial.c
	gcc -o burnSerial burnSerial.c -L$(LIBUSB) -I$(LIBUSB) -m32 -lusb-1.0

hello.xe: hello.xc
	xcc -o hello.xe hello.xc -target=XK-1

