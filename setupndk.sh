set -e

#Setup the ndk according to the selected version
export NDK_VERSION=r21
export NDK=$PWD/android-ndk-$NDK_VERSION
export ANDROID_NDK_ROOT=$NDK


wget -nc -nv -O android-ndk-$NDK_VERSION-linux-x86_64.zip "https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux-x86_64.zip"

unzip -q android-ndk-$NDK_VERSION-linux-x86_64.zip

./maketoolchain.sh

