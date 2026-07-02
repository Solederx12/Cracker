TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# ئەم دێڕانەی خوارەوە خۆکار فایلی پۆلیست دروست دەکەن بۆ ئەوەی ئیرۆرەکە نەمێنێت
$(shell echo '<?xml version="1.0" encoding="UTF-8"?>' > CyberEliteCore.plist)
$(shell echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> CyberEliteCore.plist)
$(shell echo '<plist version="1.0"><dict><key>Filter</key><dict><key>Bundles</key><array><string>com.miniclip.8ballpool</string></array></dict></dict></plist>' >> CyberEliteCore.plist)

# 1. دیاریکردنی فایلی کۆد و فڕەیمۆرکەکان
CyberEliteCore_FILES = Tweak.xm
CyberEliteCore_CFLAGS = -fobjc-arc
CyberEliteCore_FRAMEWORKS = UIKit

# 2. بەستنەوەی فایلی لایبرەری Dobby بە پڕۆژەکەوە
CyberEliteCore_LDFLAGS += ./libs/libdobby.a

include $(THEOS)/makefiles/tweak.mk
