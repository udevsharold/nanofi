ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NanoFiPrefs

NanoFiPrefs_FILES = NFPRootListController.m ../NFShared.mm
NanoFiPrefs_FRAMEWORKS = UIKit
NanoFiPrefs_PRIVATE_FRAMEWORKS = Preferences
NanoFiPrefs_INSTALL_PATH = /Library/PreferenceBundles
NanoFiPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
