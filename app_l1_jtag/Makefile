TARGET = XTAG2

APP_NAME = l1_jtag

XCC_FLAGS = -D G1 -O2 -g -Wall -D UIFM_MODE=2 -D USB_CORE=0 -fsubword-select -Wno-timing

XCC_MAP_FLAGS = -g -Xmapper --image-base -Xmapper 0x10400 -Xmapper --show-report -Xmapper --map -Xmapper MAPFILE -Wno-timing

USED_MODULES = module_usb_shared module_jtag_master module_xcore_debug module_xud module_jtag_otp_access module_xs1_su_debug


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
