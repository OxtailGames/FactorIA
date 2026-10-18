# iOS Info.plist generation, shared by two builds of the app:
#   - player/CMakeLists.txt (the app built from the engine source), and
#   - the project that `factoria export --platform ios` writes in prebuilt mode (cmake/plist.cmake next to
#     cmake/Info.plist.in; no engine source needed).
# Needs FA_GAME_BUNDLE_ID, FA_GAME_NAME, FA_GAME_VERSION and FA_GAME_ORIENTATION (landscape | portrait | any) set, and
# CMAKE_OSX_DEPLOYMENT_TARGET. FA_GAME_BUILD (optional) is the build number, CFBundleVersion; empty = FA_GAME_VERSION.
# FA_GAME_NON_EXEMPT_ENCRYPTION (optional, default OFF) is ITSAppUsesNonExemptEncryption.
# A macro (not a function) so the variables Info.plist.in reads land in the caller's scope.
set(FA_IOS_PLIST_DIR ${CMAKE_CURRENT_LIST_DIR})  # captured at include time: inside the macro it would be the caller's dir

macro(fa_ios_configure_plist out)
    if(FA_GAME_ORIENTATION STREQUAL "portrait")
        set(FA_IOS_ORIENTATIONS "<string>UIInterfaceOrientationPortrait</string>")
        set(FA_IOS_ORIENTATIONS_IPAD "<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>")
    elseif(FA_GAME_ORIENTATION STREQUAL "any")
        set(FA_IOS_ORIENTATIONS "<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>")
        set(FA_IOS_ORIENTATIONS_IPAD "<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>")
    else()
        set(FA_IOS_ORIENTATIONS "<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>")
        set(FA_IOS_ORIENTATIONS_IPAD "<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>")
    endif()
    # CFBundleVersion: the build number when given, else the version.
    if(FA_GAME_BUILD)
        set(FA_GAME_BUILD_VALUE "${FA_GAME_BUILD}")
    else()
        set(FA_GAME_BUILD_VALUE "${FA_GAME_VERSION}")
    endif()
    # ITSAppUsesNonExemptEncryption: false unless FA_GAME_NON_EXEMPT_ENCRYPTION is on (export.ios.usesNonExemptEncryption), so
    # that App Store Connect does not ask the export-compliance question at every upload.
    if(FA_GAME_NON_EXEMPT_ENCRYPTION)
        set(FA_IOS_NON_EXEMPT_ENCRYPTION "<true/>")
    else()
        set(FA_IOS_NON_EXEMPT_ENCRYPTION "<false/>")
    endif()
    # XML-escape the display name for the plist.
    string(REPLACE "&" "&amp;" FA_GAME_NAME_XML "${FA_GAME_NAME}")
    string(REPLACE "<" "&lt;" FA_GAME_NAME_XML "${FA_GAME_NAME_XML}")
    string(REPLACE ">" "&gt;" FA_GAME_NAME_XML "${FA_GAME_NAME_XML}")
    configure_file(${FA_IOS_PLIST_DIR}/Info.plist.in ${out} @ONLY)
endmacro()

# The privacy manifest: `factoria export --platform ios` writes PrivacyInfo.xcprivacy next to build_ios.sh and passes it as
# FA_GAME_PRIVACY_MANIFEST; it goes to the root of the app bundle, where App Store Connect looks for it.
macro(fa_ios_add_privacy_manifest target)
    if(FA_GAME_PRIVACY_MANIFEST)
        if(NOT EXISTS "${FA_GAME_PRIVACY_MANIFEST}")
            message(FATAL_ERROR "FA_GAME_PRIVACY_MANIFEST='${FA_GAME_PRIVACY_MANIFEST}' does not exist. "
                "Export the game again with `factoria export --platform ios` (it writes PrivacyInfo.xcprivacy next to build_ios.sh).")
        endif()
        target_sources(${target} PRIVATE "${FA_GAME_PRIVACY_MANIFEST}")
        set_source_files_properties("${FA_GAME_PRIVACY_MANIFEST}" PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    endif()
endmacro()
