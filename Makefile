# ================================================================
# Eight Ball Pool Elite Mod - Theos Makefile
# ================================================================

ARCHS = arm64
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = EightBallPool

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EightBallPoolMod

# تەنها Tweak.xm — main.mm لابرانی چونکە duplicate constructor بوو
EightBallPoolMod_FILES = Tweak.xm
EightBallPoolMod_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation

# ARC + Warnings
EightBallPoolMod_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
EightBallPoolMod_CCFLAGS = -std=c++17 -fobjc-arc -Wno-deprecated-declarations

# objc خۆکار link دەبێت؛ substrate لە tweak.mk خۆکارە
EightBallPoolMod_LDFLAGS = -lobjc

EightBallPoolMod_CFLAGS = -fobjc-arc -std=c++17

EightBallPoolMod_CCFLAGS = -std=c++17

include $(THEOS_MAKE_PATH)/tweak.mk

# ================================================================
# Post-install: restart the game process
# ================================================================
after-install::
	install.exec "killall -9 EightBallPool 2>/dev/null; true"
