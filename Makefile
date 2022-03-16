SHELL := /usr/bin/env bash
.SHELLFLAGS := -ec

# Written by Crystal with <3

# Check for required variables - TARGET and TARGET_JDK
ifndef TARGET
$(error TARGET is not set)
endif

ifndef TARGET_JDK
$(error TARGET_JDK is not set)
endif

PWD := $(shell pwd)

# Set to true if building for iOS. Requires a Mac capable of running Xcode 10 or later.
BUILD_IOS ?= 0
ifeq (1,$(BUILD_IOS))
$(warning Building for iOS $(TARGET_JDK))
else
$(warning Building for Android $(TARGET_JDK))
endif

# Set the NDK version you wish to compile with. Currently only r10e works
NDK_VERSION ?= r10e

# Set to the FreeType version you wish to compile with
FREETYPE_VERSION ?= 2.10.4
$(warning Building with FreeType $(FREETYPE_VERSION))

# Set the debug level of the JDK [release/debug/fastdebug]
JDK_DEBUG_LEVEL ?= release
$(warning Building JVM with debug level $(JDK_DEBUG_LEVEL))

# Set the variant of the JVM to compile [client/server]
ifeq (aarch32,$(TARGET_JDK))
JVM_VARIANTS ?= client
else ifeq (arm,$(TARGET_JDK))
JVM_VARIANTS ?= client
else
JVM_VARIANTS ?= server
endif
$(warning Building JVM with variant $(JVM_VARIANTS))

# Sets TARGET_SHORT
ifeq (aarch64,$(TARGET_JDK))
TARGET_SHORT ?= arm64
else
TARGET_SHORT ?= $(TARGET_JDK)
endif
# Variables specific to iOS
ifeq (1,$(BUILD_IOS))
JVM_PLATFORM  := macosx
thecc         := $(shell xcrun -find -sdk iphoneos clang)
thecxx        := $(shell xcrun -find -sdk iphoneos clang++)
thesysroot    := $(shell xcrun --sdk iphoneos --show-sdk-path)
themacsysroot := $(shell xcrun --sdk macosx --show-sdk-path)
thehostcxx    := $(PWD)/macos-host-cc
CC            := $(PWD)/ios-arm64-clang
CXX           := $(PWD)/ios-arm64-clang++
LD            := $(shell xcrun -find -sdk iphoneos ld)
HOTSPOT_DISABLE_DTRACE_PROBES := 1
ANDROID_INCLUDE := $(PWD)/ios-missing-include
else
# Variables specific to Android
JVM_PLATFORM  := linux
API           := 21
NDK           := $(PWD)/android-ndk-$(NDK_VERSION)
TOOLCHAIN     := $(NDK)/generated-toolchains/android-$(TARGET_SHORT)-toolchain
ANDROID_INCLUDE := $(TOOLCHAIN)/sysroot/usr/include
CPPFLAGS      := "-I$(ANDROID_INCLUDE) -I$(ANDROID_INCLUDE)/$(TARGET)"
LDFLAGS       := "-L$(NDK)/platforms/android-$(API)/arch-$(TARGET_SHORT)/usr/lib"
AR            :=$(TOOLCHAIN)/bin/$(TARGET)-ar
AS            :=$(TOOLCHAIN)/bin/$(TARGET)-as
CC            :=$(TOOLCHAIN)/bin/$(TARGET)-gcc
CXX           :=$(TOOLCHAIN)/bin/$(TARGET)-g++
LD            :=$(TOOLCHAIN)/bin/$(TARGET)-ld
OBJCOPY       :=$(TOOLCHAIN)/bin/$(TARGET)-objcopy
RANLIB        :=$(TOOLCHAIN)/bin/$(TARGET)-ranlib
STRIP         :=$(TOOLCHAIN)/bin/$(TARGET)-strip
endif


check:
	@echo $(BUILD_IOS)
	@echo $(FREETYPE_VERSION)
	@echo $(JDK_DEBUG_LEVEL)
	@echo $(JVM_VARIANTS)
	@echo $(NDK_VERSION)
	@echo $(TARGET)
	@echo $(TARGET_JDK)
	@echo $(TARGET_SHORT)
	@echo $(JVM_PLATFORM)
	@echo $(thecc)
	@echo $(thecxx)
	@echo $(thesysroot)
	@echo $(themacsysroot)
	@echo $(thehostcxx)
	@echo $(CC)
	@echo $(CXX)
	@echo $(LD)
	@echo $(HOTSPOT_DISABLE_DTRACE_PROBES)
	@echo $(ANDROID_INCLUDE)
	@echo $(API)
	@echo $(NDK)
	@echo $(TOOLCHAIN)
	@echo $(CPPFLAGS)
	@echo $(LDFLAGS)
	@echo $(AR)
	@echo $(AS)
	@echo $(OBJCOPY)
	@echo $(RANLIB)
	@echo $(STRIP)



ndk:

toolchain:
	$(NDK)/build/tools/make-standalone-toolchain.sh \
		--arch=$(TARGET_SHORT) \
		--platform=android-21 \
		--install-dir=$(NDK)/generated-toolchains/android-$(TARGET_SHORT)-toolchain
	cp devkit.info.$(TARGET_SHORT) $(NDK)/generated-toolchains/android-$(TARGET_SHORT)-toolchain/

get-deps:
	wget https://downloads.sourceforge.net/project/freetype/freetype2/$(FREETYPE_VERSION)/freetype-$(FREETYPE_VERSION).tar.gz
	tar xf freetype-$(FREETYPE_VERSION).tar.gz
	wget https://github.com/apple/cups/releases/download/v2.2.4/cups-2.2.4-source.tar.gz
	tar xf cups-2.2.4-source.tar.gz
	rm cups-2.2.4-source.tar.gz freetype-$(FREETYPE_VERSION).tar.gz
	if [[ '$(BUILD_IOS)' != '1'; then \
		sudo apt update; \
		sudo apt -y install autoconf python unzip zip; \
		wget -nc -nv -O android-ndk-$(NDK_VERSION)-linux-x86_64.zip "https://dl.google.com/android/repository/android-ndk-$(NDK_VERSION)-linux-x86_64.zip"; \
		unzip -q android-ndk-$(NDK_VERSION)-linux-x86_64.zip; \
	else \
		chmod +x ios-arm64-clang; \
		chmod +x ios-arm64-clang++; \
		chmod +x macos-host-cc; \
	fi

build-deps:

clone-jdk:

build-jdk-no-configure:

build-jdk:

package:
