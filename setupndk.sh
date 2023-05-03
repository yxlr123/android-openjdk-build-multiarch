set -e

#Setup the ndk according to the selected version

wget -nc -nv -O android-ndk-$NDK_VERSION-linux-x86_64.zip "https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux-x86_64.zip"

unzip -q android-ndk-$NDK_VERSION-linux-x86_64.zip

./maketoolchain.sh