TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# دڵنیابە ناوی فایلی کۆدەکەت TWEAK.xm (بە پیتە گەورەکان) بێت
CyberEliteCore_FILES = TWEAK.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit Foundation

# بەستنەوەی لایبرەرییەکان
CyberEliteCore_LDFLAGS += -L./libs -ldobby

# زیادکردنی مەرجی پێویست بۆ Dobby ئەگەر پێویستی بە هێدەر بوو
CyberEliteCore_CCFLAGS = -std=c++11

include $(THEOS)/makefiles/tweak.mk

# پڕۆسەی دروستکردنی فایلی فلتەر (Plist)
after-package::
	rm -rf .theos/obj/$(Tweak.xm).plist

before-all::
	@echo "Creating Plist filter..."
	@echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>Filter</key><dict><key>Bundles</key><array><string>com.miniclip.8ballpool</string></array></dict></dict></plist>' > CyberEliteCore.plist
