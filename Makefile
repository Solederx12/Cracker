TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# ١. لێرەدا فایلەکان و فڕەیمۆرکە بنەڕەتییەکانی ئایۆئێس دیاری دەکەین
CyberEliteCore_FILES = TWEAK.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit

# ٢. لێرەدا فایلی ڕەقی Dobby دەبەستینەوە بە پڕۆژەکەوە بە بێ ئەوەی بسڕێتەوە
CyberEliteCore_LDFLAGS += ./libs/libdobby.a

include $(THEOS)/makefiles/tweak.mk
