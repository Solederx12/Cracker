ARCHS = arm64
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = EightBallPool

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EightBallPoolMod

EightBallPoolMod_FILES = Tweak.xm
EightBallPoolMod_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation
EightBallPoolMod_PRIVATE_FRAMEWORKS = 

# بۆ ARC
EightBallPoolMod_CFLAGS = -I./ -fobjc-arc -Wno-deprecated-declarations
EightBallPoolMod_CCFLAGS = -std=c++17 -fobjc-arc

# بۆ Dobby Hooking
EightBallPoolMod_LDFLAGS = -lellekit -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk
