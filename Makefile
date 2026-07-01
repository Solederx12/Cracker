TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# ئەگەر فایلی libdobby.a لە ناو فۆڵدەرێکی پڕۆژەکەتدا بێت بە ناوی libs
CyberEliteCore_LDFLAGS += ./libs/libdobby.a

# یان ئەگەر فایلی dobby.framework بەکاردێنیت
CyberEliteCore_FRAMEWORKS += dobby

# لێرەدا تەنها ئەو کتێبخانانە بهێڵەرەوە کە پڕۆژەکەت پێویستی پێیەتی
CyberEliteCore_FILES = TWEAK.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit

include $(THEOS)/makefiles/tweak.mk
