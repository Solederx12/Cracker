ARCHS = arm64
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EightBallPoolMod
EightBallPoolMod_FILES = Tweak.xm
EightBallPoolMod_FRAMEWORKS = UIKit CoreGraphics

# پێی دەڵێین کە فایلەکانی هێدەر و لایبرەری لەناو هەمان فۆڵدەری پرۆژەکە بخوێنێتەوە
EightBallPoolMod_CFLAGS = -I./
EightBallPoolMod_LDFLAGS = -L./ -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
