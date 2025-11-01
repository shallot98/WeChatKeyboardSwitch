THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:16.5
ARCHS = arm64

INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatKeyboardSwitch

WeChatKeyboardSwitch_FILES = Tweak.xm
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
