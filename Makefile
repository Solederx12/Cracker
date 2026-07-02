TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# 1. دیاریکردنی فایلی کۆد و فڕەیمۆرکەکان (دڵنیا بەرەوە ناوی فایلی کۆدەکەت بەم شێوازەیە Tweak.xm)
CyberEliteCore_FILES = Tweak.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit

# 2. بەستنەوەی فایلی لایبرەری Dobby بە پڕۆژەکەوە
CyberEliteCore_LDFLAGS += ./libs/libdobby.a

include $(THEOS)/makefiles/tweak.mk
