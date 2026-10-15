# iOS Info.plist generation, shared by two builds of the app:
#   - player/CMakeLists.txt (the app built from the engine source), and
#   - the project that `factoria export --platform ios` writes in prebuilt mode (cmake/plist.cmake next to
#     cmake/Info.plist.in; no engine source needed).
# Needs FA_GAME_BUNDLE_ID, FA_GAME_NAME, FA_GAME_VERSION and FA_GAME_ORIENTATION (landscape | portrait | any) set, and
# CMAKE_OSX_DEPLOYMENT_TARGET. A macro (not a function) so the variables Info.plist.in reads land in the caller's scope.
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
    # XML-escape the display name for the plist.
    string(REPLACE "&" "&amp;" FA_GAME_NAME_XML "${FA_GAME_NAME}")
    string(REPLACE "<" "&lt;" FA_GAME_NAME_XML "${FA_GAME_NAME_XML}")
    string(REPLACE ">" "&gt;" FA_GAME_NAME_XML "${FA_GAME_NAME_XML}")
    configure_file(${FA_IOS_PLIST_DIR}/Info.plist.in ${out} @ONLY)
endmacro()
