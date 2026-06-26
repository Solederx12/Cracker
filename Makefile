TARGET := iphone:clang:latest:14.0
ARCHS = arm64


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Kurdish80p

# فایلەکان و فڕەیمۆرکەکانی پڕۆژەکە
Kurdish80p_FILES = TWEAK.xm
Kurdish80p_FRAMEWORKS = UIKit CoreGraphics QuartzCore

# ڕێکخستنی سیفەتەکانی کۆمپایلەر
Kurdish80p_CFLAGS = -fobjc-arc -I.

# 🎯 بەستنەوەی ڕاستەوخۆی فایلی دۆبی لەناو فۆڵدەری سەرەکی پڕۆژەکەدا
Kurdish80p_LDFLAGS = $(THEOS_PROJECT_DIR)/libdobby.a

include $(THEOS)/makefiles/tweak.mk
