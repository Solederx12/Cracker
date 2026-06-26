# لەناو Makefileـەکەتدا
TWEAK_NAME = Kurdish80p
Kurdish80p_FILES = TWEAK.xm
Kurdish80p_CFLAGS = -fobjc-arc

# زیادکردنی ئەم دێڕە بۆ دابەزاندنی ئۆتۆماتیکی (ئەگەر Theosـەکەت نوێیە)
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

