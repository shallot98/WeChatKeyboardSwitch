THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:16.5
ARCHS = arm64 arm64e
PACKAGE_VERSION = 0.1.0

INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatKeyboardSwitch

WeChatKeyboardSwitch_FILES = Tweak.xm
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
WeChatKeyboardSwitch_FRAMEWORKS = UIKit QuartzCore CoreFoundation AudioToolbox

include $(THEOS)/makefiles/tweak.mk

SUBPROJECTS += WeChatKeyboardSwitchPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
