THEOS ?= $(HOME)/theos
THEOS_MAKE_PATH ?= $(THEOS)/makefiles

include $(THEOS_MAKE_PATH)/common.mk

BUNDLE_NAME = WeChatKeyboardSwitchPrefs

WeChatKeyboardSwitchPrefs_FILES = WKSRootListController.m
WeChatKeyboardSwitchPrefs_INSTALL_PATH = /Library/PreferenceBundles
WeChatKeyboardSwitchPrefs_FRAMEWORKS = UIKit
WeChatKeyboardSwitchPrefs_PRIVATE_FRAMEWORKS = Preferences
WeChatKeyboardSwitchPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
