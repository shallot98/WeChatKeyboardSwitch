TARGET := iphone:clang:16.0:16.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatKeyboardSwipe

WeChatKeyboardSwipe_FILES = Tweak.x
WeChatKeyboardSwipe_CFLAGS = -fobjc-arc
WeChatKeyboardSwipe_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 WeChat"
