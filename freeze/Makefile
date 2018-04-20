THEOS_DEVICE_IP = 192.168.1.115
ARCHS = armv7 armv7s arm64
include /Users/artikus/theos/makefiles/common.mk

TOOL_NAME = freeze
freeze_FILES = main.mm

freeze_CODESIGN ?= ldid
freeze_CODESIGN_FLAGS ?= -S/Users/artikus/entitlements.xml

include $(THEOS_MAKE_PATH)/tool.mk

after-install::
	install.exec "chown root /usr/bin/freeze; chmod 6755 /usr/bin/freeze"
