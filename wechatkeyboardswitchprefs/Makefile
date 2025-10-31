TARGET := iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = WeChatKeyboardSwitchPrefs

WeChatKeyboardSwitchPrefs_FILES = WeChatKeyboardSwitchPrefsRootListController.m
WeChatKeyboardSwitchPrefs_FRAMEWORKS = UIKit Foundation
WeChatKeyboardSwitchPrefs_PRIVATE_FRAMEWORKS = Preferences
WeChatKeyboardSwitchPrefs_INSTALL_PATH = /Library/PreferenceBundles
WeChatKeyboardSwitchPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
