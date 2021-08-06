ARCHS = arm64 arm64e
TARGET := iphone:clang:13.0:11.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NanoFi
NanoFi_BUNDLE_EXTENSION = bundle
NanoFi_FILES = NFMNanoFi.m ../NFShared.mm
NanoFi_CFLAGS = -fobjc-arc
NanoFi_FRAMEWORKS = UIKit
NanoFi_PRIVATE_FRAMEWORKS = ControlCenterUIKit
NanoFi_INSTALL_PATH = /Library/ControlCenter/Bundles/

include $(THEOS_MAKE_PATH)/bundle.mk
