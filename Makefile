ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyDobbyTweak

MyDobbyTweak_FILES = TWEAK.xm
MyDobbyTweak_CFLAGS = -fobjc-arc

# لێرەدا بەستەرەکە (Linker) ئاگادار دەکەینەوە کە لایبرەرییەکە بخوێنێتەوە
MyDobbyTweak_LDFLAGS = -L. -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
