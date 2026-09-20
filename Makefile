ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CCWeatherModule
CCWeatherModule_FILES = src/WCCModule.m src/WCCContentViewController.m src/ConditionTables.m src/WCCPreferences.m src/WCCMedia.m src/WCCGallery.m src/WCCSettings.m
CCWeatherModule_CFLAGS = -fobjc-arc -Wno-incomplete-implementation -Wno-objc-protocol-method-implementation
CCWeatherModule_FRAMEWORKS = Foundation UIKit CoreGraphics CoreLocation ImageIO AVFoundation CoreMedia QuartzCore
# Private APIs are resolved at runtime; no SDK-private link stubs required.
CCWeatherModule_INSTALL_PATH = /Library/ControlCenter/Bundles
CCWeatherModule_RESOURCE_DIRS = Resources
CCWeatherModule_INFOPLIST = Resources/Info.plist

include $(THEOS_MAKE_PATH)/bundle.mk
