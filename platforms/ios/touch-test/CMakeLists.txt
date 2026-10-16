# A UI test that taps the middle of the screen of an app that is already running in the iOS Simulator. simctl cannot
# inject touches; XCUITest (Apple's UI testing) can, and it runs on the hosted macOS runners. scripts/ios-smoke.sh
# builds this project, then runs the test while the player is in front (with its console captured) and checks that
# the player logged the touch at the right place.
#
#   cmake -S platforms/ios/touch-test -B build/ios-touch-test -G Xcode -DCMAKE_SYSTEM_NAME=iOS \
#         -DCMAKE_OSX_SYSROOT=iphonesimulator
#   TEST_RUNNER_FA_TOUCH_BUNDLE_ID=<bundleId> xcodebuild test -project build/ios-touch-test/FactoriaTouch.xcodeproj \
#         -scheme FactoriaTouchHost -destination id=<simulator udid> CODE_SIGNING_ALLOWED=NO
#
# Two targets: an empty host app (Xcode builds a UI test runner only for a test that names a target app) and the UI
# test bundle, which drives the player by bundle id and never launches the host.
cmake_minimum_required(VERSION 3.24)
project(FactoriaTouch LANGUAGES C OBJC)

set(CMAKE_XCODE_GENERATE_SCHEME ON)
set(CMAKE_OSX_DEPLOYMENT_TARGET 16.3)

add_executable(FactoriaTouchHost MACOSX_BUNDLE host.m)
set_target_properties(FactoriaTouchHost PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER dev.factoria.touchhost
    MACOSX_BUNDLE_BUNDLE_NAME FactoriaTouchHost
    MACOSX_BUNDLE_BUNDLE_VERSION 1
    MACOSX_BUNDLE_SHORT_VERSION_STRING 1.0
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER dev.factoria.touchhost
    XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE YES
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
target_link_libraries(FactoriaTouchHost PRIVATE "-framework UIKit" "-framework Foundation")

add_library(FactoriaTouchUITests MODULE touch_tests.m)
set_target_properties(FactoriaTouchUITests PROPERTIES
    BUNDLE TRUE
    BUNDLE_EXTENSION xctest
    XCTEST TRUE  # with XCTEST_TESTEE: CMake lists the bundle in the Test action of the host's scheme
    XCTEST_TESTEE FactoriaTouchHost
    XCODE_PRODUCT_TYPE com.apple.product-type.bundle.ui-testing
    XCODE_ATTRIBUTE_TEST_TARGET_NAME FactoriaTouchHost
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER dev.factoria.touchuitests
    XCODE_ATTRIBUTE_GENERATE_INFOPLIST_FILE YES
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
    XCODE_ATTRIBUTE_ENABLE_TESTING_SEARCH_PATHS YES)
target_link_libraries(FactoriaTouchUITests PRIVATE "-framework XCTest" "-framework UIKit" "-framework Foundation")
add_dependencies(FactoriaTouchUITests FactoriaTouchHost)
