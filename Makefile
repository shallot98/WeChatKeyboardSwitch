TARGET := iphone:clang:16.5:16.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatKeyboardSwitch

WeChatKeyboardSwitch_FILES = Tweak.xm
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc
WeChatKeyboardSwitch_FRAMEWORKS = UIKit Foundation
WeChatKeyboardSwitch_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += wechatkeyboardswitchprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
