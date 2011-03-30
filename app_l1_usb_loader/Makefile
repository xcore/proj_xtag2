TARGET = XTAG2.xn

APP_NAME = l1_usb_loader.xe

XCC_FLAGS = -Xmapper --image-base -Xmapper 0x1b000 -Xmapper --map -Xmapper MAPFILE -Wall -O3 -D UIFM_MODE=2 -report -fsubword-select -DUSB_CORE=0 -D G1 

USED_MODULES = module_usb_shared module_xud

XCC_FLAGS_main.xc = -DUSB_CORE=0


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
