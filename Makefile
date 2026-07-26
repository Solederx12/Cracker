# ================================================================
# Eight Ball Pool Elite Mod - Theos Makefile
# ================================================================

ARCHS = arm64
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = EightBallPool

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EightBallPoolMod

EightBallPoolMod_FILES = Tweak.xm
EightBallPoolMod_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation
EightBallPoolMod_PRIVATE_FRAMEWORKS =

# ARC + Warnings
EightBallPoolMod_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
EightBallPoolMod_CCFLAGS = -std=c++17 -fobjc-arc -Wno-deprecated-declarations

# Substrate / Substrate-like hooking
EightBallPoolMod_LDFLAGS = -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk

# ================================================================
# Post-install: restart the game process
# ================================================================
after-install::
	install.exec "killall -9 EightBallPool 2>/dev/null; true"
