This directory contains binary images that can be used to burn an XTAG2.

There is a directory for each version:

* 00.02 - the firmware burned into XTAG2 that uses XUD version 0.5

* 00.04 - firmware using XUD version 0.6

Each version directory contains two subdirectory:

* A directory that contains the binary including the relocator/decompressor

* A directory that contains a binary that will burn the
  relocator/decompressor into OTP. Do not execute binaries in this
  directory as they will knacker your OTP.
