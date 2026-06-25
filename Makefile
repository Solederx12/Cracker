TARGET := iphoneos:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Kurdish80p

# فایلەکانی پرۆژەکە
Kurdish80p_FILES = TWEAK.xm
Kurdish80p_FRAMEWORKS = UIKit CoreGraphics QuartzCore

# 🛠️ ڕێکخستنی سیفەتەکانی کۆمپایلەر
Kurdish80p_CFLAGS = -fobjc-arc -I.

# 🎯 بەستنەوەی ڕاستەوخۆی فایلی دۆبی بە ناونیشانی سەرەکی پڕۆژەکە (PWD)
Kurdish80p_LDFLAGS = $(PWD)/libdobby.a

include $(THEOS)/makefiles/tweak.mk
