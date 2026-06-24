TARGET := iphoneos:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Kurdish80p

Kurdish80p_FILES = TWEAK.xm
Kurdish80p_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS)/makefiles/tweak.mk
