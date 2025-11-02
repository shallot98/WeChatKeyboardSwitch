THEOS ?= $(HOME)/theos
THEOS_MAKE_PATH ?= $(THEOS)/makefiles

THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:16.5
ARCHS = arm64 arm64e
PACKAGE_VERSION = 0.1.0

INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS_MAKE_PATH)/common.mk

TWEAK_NAME = WeChatKeyboardSwitch

WeChatKeyboardSwitch_FILES = Tweak.xm
WeChatKeyboardSwitch_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
WeChatKeyboardSwitch_FRAMEWORKS = UIKit Foundation AudioToolbox
WeChatKeyboardSwitch_PRIVATE_FRAMEWORKS = UIKitCore
WeChatKeyboardSwitch_LDFLAGS := $(filter-out -multiply_defined%,$(WeChatKeyboardSwitch_LDFLAGS))

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += WeChatKeyboardSwitchPrefs
include $(THEOS_MAKE_PATH)/aggregate.mk
