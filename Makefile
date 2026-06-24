export ARCHS = arm64 arm64e
export TARGET = iphone:clang:14.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iOSModMenu

iOSModMenu_FILES = TWEAK.xm
iOSModMenu_CFLAGS = -fobjc-arc
# لێرەدا فریمۆرکەکانمان زیاد کرد بۆ ئەوەی بە وێنەکەدا بێن
iOSModMenu_FRAMEWORKS = UIKit QuartzCore CoreGraphics Foundation SystemConfiguration
# لێرەدا کتێبخانە پێویستەکانمان زیاد کرد
iOSModMenu_LDFLAGS = -lsubstrate

include $(THEOS)/makefiles/tweak.mk
