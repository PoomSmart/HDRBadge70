GO_EASY_ON_ME = 1
ARCHS = armv7 arm64

include theos/makefiles/common.mk
TWEAK_NAME = HDRBadge70
HDRBadge70_FILES = Tweak.xm
HDRBadge70_FRAMEWORKS = UIKit
HDRBadge70_PRIVATE_FRAMEWORKS = PhotoLibrary

include $(THEOS_MAKE_PATH)/tweak.mk
