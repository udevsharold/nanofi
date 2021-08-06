export ARCHS = arm64 arm64e

export DEBUG = 0
export FINALPACKAGE = 1

export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NanoFi

$(TWEAK_NAME)_FILES = $(wildcard *.xm) $(wildcard *.mm)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 terminusd"
SUBPROJECTS += nanoficcmodule
SUBPROJECTS += nanofiprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
