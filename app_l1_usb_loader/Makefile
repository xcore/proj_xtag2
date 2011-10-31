TARGET = L1_XTAG

APP_NAME = l1_usb_loader.xe

XCC_FLAGS = -Xmapper --image-base -Xmapper 0x1b000 -Xmapper --map -Xmapper MAPFILE -Wall -O3 -D UIFM_MODE=2 -report -fsubword-select -DUSB_CORE=0 -D G1 

USED_MODULES = module_usb_shared module_xud

XCC_FLAGS_main.xc = -DUSB_CORE=0


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
