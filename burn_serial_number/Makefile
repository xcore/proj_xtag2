all: burnSerial hello.xe

burnSerial: burnSerial.c
	gcc -o burnSerial burnSerial.c -L. -m32 -lusb-1.0.0

hello.xe: hello.xc
	xcc -o hello.xe hello.xc

