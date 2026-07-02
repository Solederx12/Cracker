TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# 1. دیاریکردنی فایلی کۆد و فڕەیمۆرکەکان (لێرەدا بەپێی لۆگەکەت TWEAK.xm ڕاستە)
CyberEliteCore_FILES = TWEAK.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit

# 2. بەستنەوەی فایلی لایبرەری Dobby بە پڕۆژەکەوە
CyberEliteCore_LDFLAGS += ./libs/libdobby.a

include $(THEOS)/makefiles/tweak.mk

# 3. ئەم بەشە خۆکار هەردوو ناوی فلتەرەکە دروست دەکات لە هەمان فۆڵدەر پێش کۆمپایل بوون
before-all::
	echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>Filter</key><dict><key>Bundles</key><array><string>com.miniclip.8ballpool</string></array></dict></dict></plist>' > Filter.plist
	echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>Filter</key><dict><key>Bundles</key><array><string>com.miniclip.8ballpool</string></array></dict></dict></plist>' > CyberEliteCore.plist
