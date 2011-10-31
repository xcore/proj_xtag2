TARGET = XTAG2

APP_NAME = l1_jtag

XCC_FLAGS = -D G1 -O2 -g -Wall -D UIFM_MODE=2 -D USB_CORE=0 -fsubword-select -Wno-timing

XCC_MAP_FLAGS = -g -Xmapper --image-base -Xmapper 0x10400 -Xmapper --show-report -Xmapper --map -Xmapper MAPFILE -Wno-timing

USED_MODULES = module_usb_shared module_jtag_master module_xcore_debug module_xud


#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
