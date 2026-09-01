# Cross-compile the iOS arm64 products from a Linux host.
#
# Needs upstream clang and lld (Debian 13: clang-19 lld-19 llvm-19) and an
# iPhoneOS SDK, either copied out of Xcode or sparse-cloned from
# github.com/xybp888/iOS-SDKs. Nothing from Theos or xtool. See README.md,
# "iOS from Linux".
#
#   cmake -S runtime -B build-ios -G Ninja -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_TOOLCHAIN_FILE=cmake/ios-linux-toolchain.cmake \
#       -DCMAKE_DISABLE_FIND_PACKAGE_absl=TRUE -DAURORA_DAWN_PROVIDER=package

set(IOS_SDK "/opt/iPhoneOS.sdk" CACHE PATH "iPhoneOS SDK copied from Xcode")
set(MKW_IOS_LLVM_BIN "/usr/lib/llvm-19/bin" CACHE PATH "Directory holding clang, ld64.lld and llvm-ar")
set(MKW_IOS_CLANG_RT "" CACHE FILEPATH
    "Optional: Xcode's libclang_rt.ios.a. Left empty, src/platform/ios/compiler_rt_shim.c covers what the runtime needs")
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES IOS_SDK MKW_IOS_LLVM_BIN MKW_IOS_CLANG_RT)

set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_PROCESSOR arm64)
set(CMAKE_OSX_ARCHITECTURES arm64 CACHE STRING "")
set(CMAKE_OSX_DEPLOYMENT_TARGET 17.0 CACHE STRING "")
set(CMAKE_OSX_SYSROOT "${IOS_SDK}" CACHE PATH "")
set(CMAKE_SYSROOT "${IOS_SDK}")

set(CMAKE_C_COMPILER "${MKW_IOS_LLVM_BIN}/clang")
set(CMAKE_CXX_COMPILER "${MKW_IOS_LLVM_BIN}/clang++")
set(CMAKE_OBJC_COMPILER "${MKW_IOS_LLVM_BIN}/clang")
set(CMAKE_OBJCXX_COMPILER "${MKW_IOS_LLVM_BIN}/clang++")
set(CMAKE_ASM_COMPILER "${MKW_IOS_LLVM_BIN}/clang")
set(CMAKE_AR "${MKW_IOS_LLVM_BIN}/llvm-ar" CACHE FILEPATH "")
set(CMAKE_RANLIB "${MKW_IOS_LLVM_BIN}/llvm-ranlib" CACHE FILEPATH "")
set(CMAKE_STRIP "${MKW_IOS_LLVM_BIN}/llvm-strip" CACHE FILEPATH "")
set(CMAKE_INSTALL_NAME_TOOL "${MKW_IOS_LLVM_BIN}/llvm-install-name-tool" CACHE FILEPATH "")
set(CMAKE_LIPO "${MKW_IOS_LLVM_BIN}/llvm-lipo" CACHE FILEPATH "")
set(CMAKE_OTOOL "${MKW_IOS_LLVM_BIN}/llvm-otool" CACHE FILEPATH "")
set(CMAKE_LINKER "${MKW_IOS_LLVM_BIN}/ld64.lld" CACHE FILEPATH "")

foreach(lang C CXX OBJC OBJCXX ASM)
    set(CMAKE_${lang}_COMPILER_TARGET arm64-apple-ios17.0)
endforeach()

# Apple's clang searches the SDK's SubFrameworks implicitly and UIKit's own
# headers import from there.
foreach(lang C CXX OBJC OBJCXX)
    set(CMAKE_${lang}_FLAGS_INIT "-iframework ${IOS_SDK}/System/Library/SubFrameworks")
endforeach()

set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=lld ${MKW_IOS_CLANG_RT}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-fuse-ld=lld ${MKW_IOS_CLANG_RT}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-fuse-ld=lld ${MKW_IOS_CLANG_RT}")
string(STRIP "${CMAKE_EXE_LINKER_FLAGS_INIT}" CMAKE_EXE_LINKER_FLAGS_INIT)

set(CMAKE_FIND_ROOT_PATH "${IOS_SDK}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
