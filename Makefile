ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Kurdish80p
Kurdish80p_FILES = TWEAK.xm
Kurdish80p_CFLAGS = -fobjc-arc

# 🛠️ لێرەدا فایلی ستاتیکی Dobby بە دایلیبەکەتەوە دەبەستینەوە
Kurdish80p_OBJ_FILES = libdobby.a

include $(THEOS_MAKE_PATH)/tweak.mk
