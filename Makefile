ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CyberEliteCore

# خوێندنەوەی سەرجەم فایلەکانی تویکەکە و مێنوو بەبێ کێشە
CyberEliteCore_FILES = TWEAK.xm $(wildcard SCLAlertView/*.m)
CyberEliteCore_CFLAGS = -fobjc-arc -std=c++11 -IVendor/

# بەستنەوەی لایبرەری dobby لەگەڵ substitute بە شێوەی دروست
CyberEliteCore_LDFLAGS = -lsubstitute -L. -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
