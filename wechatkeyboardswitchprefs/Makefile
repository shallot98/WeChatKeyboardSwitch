TARGET := iphone:clang:latest:16.5
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = WeChatKeyboardSwitchPrefs

WeChatKeyboardSwitchPrefs_FILES = WeChatKeyboardSwitchPrefsRootListController.m
WeChatKeyboardSwitchPrefs_FRAMEWORKS = UIKit
WeChatKeyboardSwitchPrefs_PRIVATE_FRAMEWORKS = Preferences
WeChatKeyboardSwitchPrefs_INSTALL_PATH = /Library/PreferenceBundles
WeChatKeyboardSwitchPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
