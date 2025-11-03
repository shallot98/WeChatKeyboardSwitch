SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

THEOS ?= $(HOME)/theos
THEOS_MAKE_PATH ?= $(THEOS)/makefiles

ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.5

include $(THEOS_MAKE_PATH)/common.mk

BUNDLE_NAME = WeChatKeyboardSwitchPrefs

WeChatKeyboardSwitchPrefs_FILES = WKSRootListController.m
WeChatKeyboardSwitchPrefs_INSTALL_PATH = /Library/PreferenceBundles
WeChatKeyboardSwitchPrefs_FRAMEWORKS = UIKit
WeChatKeyboardSwitchPrefs_PRIVATE_FRAMEWORKS = Preferences
WeChatKeyboardSwitchPrefs_CFLAGS = -fobjc-arc
WeChatKeyboardSwitchPrefs_LDFLAGS += -F/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/bundle.mk
