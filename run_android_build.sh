#!/bin/bash

RESULT_PATH="/$HOME/libbitcoin-android-result"
BUILD_DIR="/$HOME/libbitcoin-android-builddir"

rm -rf $RESULT_PATH
rm -rf $BUILD_DIR

BUILD_TOOLS="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"

ANDROID_API=28
ANDROID_TARGETS=("aarch64-linux-android" "armv7a-linux-androideabi" "i686-linux-android" "x86_64-linux-android")

for ARCH in "${ANDROID_TARGETS[@]}"; do

    echo "Building libs for $ARCH...\n\n"

    git clean -dfX

    export CC="$BUILD_TOOLS/$ARCH$ANDROID_API-clang"
    export CXX="$BUILD_TOOLS/$ARCH$ANDROID_API-clang++"
    
    PLATFORM_TOOLSET=`echo $ARCH | tr "_-" "."`
    export BOOST_TOOLSET="clang-$PLATFORM_TOOLSET"
    export BOOST_CUSTOM_OPTIONS="target-os=android"
    export CUSTOM_CONFIGURE_OPTIONS="--host=$ARCH"

    bash ./build.sh --prefix="$RESULT_PATH/$ARCH" --build-dir="$BUILD_DIR/$ARCH" --with-examples=no 2>&1 | tee build-android.log

done


# cp -rf ../libbitcoin-prefix/lib/*.a ~/Documents/Unreal\ Projects/CppProject/Plugins/Stratis/Source/ThirdParty/Libbitcoin/bin/Linux/