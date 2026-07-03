TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# 🔥 چارەسەری کۆتایی: هەموو فایلەکانی (.xm و .mm و .m) بە یەکەوە و بەبێ کێشەی پیت کۆمپایل دەکات
CyberEliteCore_FILES = $(wildcard *.xm *.mm *.m)
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit Foundation

# بەستنەوەی لایبرەرییەکان
CyberEliteCore_LDFLAGS += -L./libs -ldobby

# ڕێکخستنی ستانداردی سی پڵەس پڵەس بۆ دۆبی
CyberEliteCore_OBJCCFLAGS = -std=c++11

include $(THEOS)/makefiles/tweak.mk

# دروستکردنی فایلی فلتەر (Plist) پێش دەستپێکردنی کۆمپایل بۆ ئەوەی هیچ کات ئیرۆری پڵێست نەدات
before-all::
	@echo "Creating Plist filter..."
	@echo '{ Filter = { Bundles = ( "com.miniclip.8ballpool" ); }; }' > CyberEliteCore.plist

clean::
	rm -f CyberEliteCore.plist
