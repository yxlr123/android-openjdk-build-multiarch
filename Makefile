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
TARGET_PHYS  ?= aarch32-linux-androideabi
else ifeq (arm,$(TARGET_JDK))
JVM_VARIANTS ?= client
TARGET_JDK   ?= aarch32
TARGET_PHYS  ?= aarch32-linux-androideabi
else
JVM_VARIANTS ?= server
TARGET_PHYS  ?= $(TARGET)
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

deps:
	wget https://downloads.sourceforge.net/project/freetype/freetype2/$(FREETYPE_VERSION)/freetype-$(FREETYPE_VERSION).tar.gz; \
	tar xf freetype-$(FREETYPE_VERSION).tar.gz; \
	wget https://github.com/apple/cups/releases/download/v2.2.4/cups-2.2.4-source.tar.gz; \
	tar xf cups-2.2.4-source.tar.gz; \
	rm cups-2.2.4-source.tar.gz freetype-$(FREETYPE_VERSION).tar.gz; \
	if [[ '$(BUILD_IOS)' != '1' ]]; then \
		sudo apt update; \
		sudo apt -y install autoconf python unzip zip; \
		wget -nc -nv -O android-ndk-$(NDK_VERSION)-linux-x86_64.zip "https://dl.google.com/android/repository/android-ndk-$(NDK_VERSION)-linux-x86_64.zip"; \
		unzip -q android-ndk-$(NDK_VERSION)-linux-x86_64.zip; \
		$(NDK)/build/tools/make-standalone-toolchain.sh \
		--arch=$(TARGET_SHORT) \
		--platform=android-21 \
		--install-dir=$(NDK)/generated-toolchains/android-$(TARGET_SHORT)-toolchain; \
		cp devkit.info.$(TARGET_SHORT) $(NDK)/generated-toolchains/android-$(TARGET_SHORT)-toolchain/; \
		cd freetype-$(FREETYPE_VERSION); \
		export PATH=$(TOOLCHAIN)/bin:$$PATH; \
		./configure \
			--host=$(TARGET) \
			--prefix=$(PWD)/build_android-$(TARGET_SHORT) \
			--without-zlib \
			--with-png=no \
			--with-harfbuzz=no $$EXTRA_ARGS; \
	else \
		chmod +x ios-arm64-clang; \
		chmod +x ios-arm64-clang++; \
		chmod +x macos-host-cc; \
		LDFLAGS=-"arch arm64 -isysroot $(thesysroot) -miphoneos-version-min=12.0"; \
		export CC=$(thecc); \
		export CXX=$(thecxx); \
		cd freetype-$(FREETYPE_VERSION); \
		./configure \
			--host=$(TARGET) \
			--prefix=$(PWD)/build_android-$(TARGET_SHORT) \
			--enable-shared=no --enable-static=yes \
			--without-zlib \
			--with-brotli=no \
			--with-png=no \
			--with-harfbuzz=no \
			"CFLAGS=-arch arm64 -pipe -std=c99 -Wno-trigraphs -fpascal-strings -O2 -Wreturn-type -Wunused-variable -fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=12.0 -I$(thesysroot)/usr/include/libxml2/ -isysroot $(thesysroot)" \
			AR=/usr/bin/ar \
			"LDFLAGS=$$LDFLAGS"; \
	fi; \
	CFLAGS=-fno-rtti; \
	CXXFLAGS=-fno-rtti; \
	make -j4; \
	make install; \
	if [ -f "$${namefreetype}.a" ]; then \
		clang -fPIC -shared $$LDFLAGS -lbz2 -Wl,-all_load $${namefreetype}.a -o $${namefreetype}.dylib; \
	fi

clone-jdk:
	if [ "$(TARGET_JDK)" == "arm" ]; then
		git clone --depth 1 https://github.com/PojavLauncherTeam/openjdk-aarch32-jdk8u openjdk
	elif [ "$(BUILD_IOS)" == "1" ]; then
		git clone --depth 1 --branch ios https://github.com/PojavLauncherTeam/openjdk-multiarch-jdk8u openjdk
	else
		git clone --depth 1 https://github.com/PojavLauncherTeam/openjdk-multiarch-jdk8u openjdk
	fi

jdk-no-configure:
	export FREETYPE_DIR=$(PWD)/freetype-$(FREETYPE_VERSION)/build_android-$(TARGET_SHORT); \
	export CUPS_DIR=$(PWD)/cups-2.2.4; \
	cd openjdk/build/$(JVM_PLATFORM)-$(TARGET_JDK)-normal-$(JVM_VARIANTS)-$(JDK_DEBUG_LEVEL); \
	make JOBS=4 images

jdk:
	export FREETYPE_DIR=$(PWD)/freetype-$(FREETYPE_VERSION)/build_android-$(TARGET_SHORT); \
	export CUPS_DIR=$(PWD)/cups-2.2.4; \
	export CFLAGS+=" -DLE_STANDALONE"; \
	if [ "$(BUILD_IOS)" != "1" ]; then \
		export CFLAGS+=" -O3"; \
		ln -s -f /usr/include/X11 $(ANDROID_INCLUDE)/; \
		ln -s -f /usr/include/fontconfig $(ANDROID_INCLUDE)/; \
		AUTOCONF_x11arg="--x-includes=$(ANDROID_INCLUDE)/X11"; \
		export LDFLAGS+=" -L$(PWD)/dummy_libs"; \
		sudo apt -y install systemtap-sdt-dev gcc-multilib g++-multilib libxtst-dev libasound2-dev libelf-dev libfontconfig1-dev libx11-dev; \
		mkdir -p dummy_libs; \
		ar cru dummy_libs/libpthread.a; \
		ar cru dummy_libs/libthread_db.a; \
	else \
		ln -s -f /opt/X11/include/X11 $(ANDROID_INCLUDE)/; \
		export platform_args="--with-toolchain-type=clang"; \
		export AUTOCONF_x11arg="--with-x=/opt/X11/include/X11 --prefix=/usr/lib"; \
		export sameflags="-arch arm64 -isysroot $(thesysroot) -miphoneos-version-min=12.0 -DHEADLESS=1 -I$(PWD)/ios-missing-include -Wno-implicit-function-declaration"; \
		export CFLAGS+=" $$sameflags"; \
		export CXXFLAGS="$$sameflags"; \
		HOMEBREW_NO_AUTO_UPDATE=1 brew install ldid xquartz; \
	fi; \
	ln -s -f $(CUPS_DIR)/cups $(ANDROID_INCLUDE)/; \
	cd openjdk; \
	bash ./configure \
		--openjdk-target=$TARGET_PHYS \
		--with-extra-cflags="$$CFLAGS" \
		--with-extra-cxxflags="$$CFLAGS" \
		--with-extra-ldflags="$$LDFLAGS" \
		--enable-option-checking=fatal \
		--with-jdk-variant=normal \
		--with-jvm-variants="$(JVM_VARIANTS) \
		--with-cups-include=$$CUPS_DIR \
		--with-devkit=$$TOOLCHAIN \
		--with-debug-level=$$JDK_DEBUG_LEVEL \
		--with-fontconfig-include=$(ANDROID_INCLUDE) \
		--with-freetype-lib=$$FREETYPE_DIR/lib \
		--with-freetype-include=$$FREETYPE_DIR/include/freetype2 \
		$$AUTOCONF_x11arg $$AUTOCONF_EXTRA_ARGS \
		--x-libraries=/usr/lib \
		$$platform_args; \
	cd build/$(JVM_PLATFORM)-$(TARGET_JDK)-normal-$(JVM_VARIANTS)-$(JDK_DEBUG_LEVEL); \
	make JOBS=4 images

package:
	if [ "$(BUILD_IOS)" != "1" ]; then \
		git clone https://github.com/termux/termux-elf-cleaner; \
		cd termux-elf-cleaner; \
		make CFLAGS=__ANDROID_API__=24 termux-elf-cleaner; \
		chmod +x termux-elf-cleaner; \
		cd ..; \
		findexec() { find $1 -type f -name "*" -not -name "*.o" -exec sh -c '; \
			case "$(head -n 1 "$1")" in; \
			  ?ELF*) exit 0;;; \
			  MZ*) exit 0;;; \
			  #!*/ocamlrun*)exit0;;; \
			esac; \
		exit 1; \
		' sh {} \; -print; \
		}; \
		findexec jreout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner; \
		findexec jdkout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner; \
	fi; \
	sudo cp -R jre_override/lib/* jreout/lib/; \
	sudo cp -R jre_override/lib/* jdkout/jre/lib; \
	cd jreout; \
	tar cJf ../jre8-$(TARGET_SHORT)-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .; \
	cd ../jdkout; \
	tar cJf ../jdk8-$(TARGET_SHORT)-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .
