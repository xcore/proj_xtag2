TARGET = XS1-L1A-LQ64

APP_NAME = app_l1_otp_programmer.xe

XCC_FLAGS   	= -D G1 -DSPDIF -O2 -g -Wall -lotp_l1

USED_MODULES =

# Use the latest 1v* version of module_xcommon
-include ../module_xcommon/build/Makefile.common
-include ../../xcommon/module_xcommon/build/Makefile.common

# The final target of the build. This is usually dependent on a binary file
# in the $(BIN_DIR) directory e.g.
#
#  all : $(BIN_DIR)/my_app.xe

all: $(BIN_DIR)/$(APP_NAME).xe
	@echo Build Complete

clean: clean_common
