# لەناو Makefileـەکەتدا
TWEAK_NAME = Kurdish80p
Kurdish80p_FILES = TWEAK.xm
Kurdish80p_CFLAGS = -fobjc-arc

# زیادکردنی ئەم دێڕە بۆ دابەزاندنی ئۆتۆماتیکی (ئەگەر Theosـەکەت نوێیە)
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

# یانیش بەکارهێنانی Submodule بۆ Dobby
# git submodule add https://github.com/jmpews/Dobby.git libs/dobby
