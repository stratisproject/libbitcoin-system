#!/bin/bash

RESULT_PATH="$HOME/libbitcoin-ios-result"
BUILD_DIR="$HOME/libbitcoin-ios-builddir"

rm -rf $RESULT_PATH
rm -rf $BUILD_DIR

cp ios-user-config.jam "$HOME/user-config.jam"

build_darwin() {
    git clean -dfX

    MIN_IOS_VERSION=14.0

    export BOOST_CUSTOM_OPTIONS=""

    export CC=$(xcrun --find --sdk "${SDK}" clang)
    export CXX=$(xcrun --find --sdk "${SDK}" clang++)

    export SDK_PATH=$(xcrun --sdk "${SDK}" --show-sdk-path)

    export CFLAGS="${ARCH_FLAGS} -miphoneos-version-min=${MIN_IOS_VERSION} -isysroot ${SDK_PATH} -fembed-bitcode"
    export CXXFLAGS="${CFLAGS}"
    export LDFLAGS="${CFLAGS}"

    bash ./build.sh --prefix="$RESULT_PATH/$SDK" --build-dir="$BUILD_DIR/$SDK" --with-examples=no 2>&1 | tee build-$SDK.log
}

SDK="iphoneos"
ARCH_FLAGS="-arch arm64 -arch arm64e"
export BOOST_TOOLSET="darwin-ios"
export CUSTOM_CONFIGURE_OPTIONS="--host=arm-apple-darwin"
build_darwin

SDK="iphonesimulator"
ARCH_FLAGS="-arch x86_64"
export BOOST_TOOLSET="darwin-iossim"
export CUSTOM_CONFIGURE_OPTIONS="--host=x86_64-apple-darwin"
build_darwin
