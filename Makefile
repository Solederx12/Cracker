TARGET := iphoneos:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Kurdish80p

# فایلەکانی پرۆژەکە
Kurdish80p_FILES = TWEAK.xm
Kurdish80p_FRAMEWORKS = UIKit CoreGraphics QuartzCore

# ➕ زیادکردنی کتێبخانەی دۆبی بۆ ناو پڕۆژەکە
Kurdish80p_LIBRARIES = dobby

# 🛠️ ڕێکخستنی شوێنی گەڕان بۆ فایلەکانی Dobby لە ناو فۆڵدەرەکەدا
Kurdish80p_CFLAGS = -fobjc-arc -I.
Kurdish80p_LDFLAGS = -L.

include $(THEOS)/makefiles/tweak.mk
