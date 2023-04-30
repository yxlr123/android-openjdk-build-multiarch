#!/bin/bash
set -e

. setdevkitpath.sh
  
$NDK/build/tools/make_standalone_toolchain.py \
	--arch=${TARGET_SHORT} \
	--api=21 \
	--install-dir=$NDK/generated-toolchains/android-${TARGET_SHORT}-toolchain
cp devkit.info.${TARGET_SHORT} $NDK/generated-toolchains/android-${TARGET_SHORT}-toolchain/
