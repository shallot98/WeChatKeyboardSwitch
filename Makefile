TARGET := iphone:clang:16.5:16.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatIMEGestureSwitch

WeChatIMEGestureSwitch_FILES = Tweak.x
WeChatIMEGestureSwitch_CFLAGS = -fobjc-arc
WeChatIMEGestureSwitch_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
