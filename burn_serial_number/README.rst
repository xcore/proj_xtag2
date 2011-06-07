Burning Serial Numbers
----------------------


Once you have programmed the OTP of an XTAG2 with the code for it to be a
USB bootloader, you need to program the top words of the OTP with the
serial number to be used.

To do this follow the following steps, at present it only works on a Mac:

#. run `make all`

#. edit `burn_and_test.sh` and change the options to suit your taste

#. run `burn_and_test.sh`


Options for `burnSerial` are:

* -l list devices

* -s SERIALNUMBER supply a 16 character serial number.

* -r XXX create a random serial number starting with XXX

* -x XXXXXX create an XMOS random serial number starting with XXXXXX

Note that once you have burned a serial number, you cannot change it.

TODO: make Makefile work with Linux32/Linux64

TODO: port burnSerial to WINDOWS.
