THEOS_DEVICE_IP = 192.168.1.115
ARCHS = armv7 armv7s arm64
include $(THEOS)/makefiles/common.mk

TOOL_NAME = freeze
freeze_FILES = main.mm

include $(THEOS_MAKE_PATH)/tool.mk

after-install::
	install.exec "chmod 4755 /usr/bin/freeze"
