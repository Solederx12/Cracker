TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# ⚠️ زۆر گرنگە: دڵنیابە ناوی فایلی کۆدەکەت لە گیتھەب ڕێک بە پیتی گەورە بێت: TWEAK.xm
CyberEliteCore_FILES = TWEAK.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit Foundation

# بەستنەوەی لایبرەرییەکان
CyberEliteCore_LDFLAGS += -L./libs -ldobby

# ڕێکخستنی ستانداردی سی پڵەس پڵەس بۆ دۆبی
CyberEliteCore_OBJCCFLAGS = -std=c++11

include $(THEOS)/makefiles/tweak.mk

# دروستکردنی فایلی فلتەر (Plist) پێش دەستپێکردنی کۆمپایل بە شێوازێکی پارێزراو
before-all::
	@echo "Creating Plist filter..."
	@echo '{ Filter = { Bundles = ( "com.miniclip.8ballpool" ); }; }' > CyberEliteCore.plist

# سڕینەوەی فایلی کاتی دوای پاککردنەوەی پڕۆژەکە
clean::
	rm -f CyberEliteCore.plist
