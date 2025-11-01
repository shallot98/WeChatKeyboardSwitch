TARGET := iphone:clang:latest:16.5
ARCHS = arm64
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatKeyboardSwitch

WeChatKeyboardSwitch_FILES = Tweak.x
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc -Werror
WeChatKeyboardSwitch_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
