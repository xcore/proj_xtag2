LIBUSB = ../../xmos_libusb_binaries/libusb/Mac
OTPPROGRAMMER = ../app_l1_otp_programmer/bin/XS1-L1A-LQ64/app_l1_otp_programmer.xe

all: burnSerial hello.xe

burnSerial: burnSerial.c
	gcc -o burnSerial burnSerial.c -L$(LIBUSB) -I$(LIBUSB) -m32 -lusb-1.0

hello.xe: hello.xc
	xcc -o hello.xe hello.xc -target=XK-1

# These lines are not done by default - a safe one is embedded in burnSerial.

app_l1_otp_programmer.h: $(OTPPROGRAMMER)
	xobjdump --split --strip $(OTPPROGRAMMER)
	od -t x4 image_n0c0.bin | awk 'BEGIN{print "int burnData[] = {"} END {print "};"} {for(i=2;i<NF;i++) {print "  0x" $$i ","}}' > app_l1_otp_programmer.h
	rm image_n0c0.bin platform_def.xn program_info.txt

