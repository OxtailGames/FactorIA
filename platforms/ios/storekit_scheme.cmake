# Wires a StoreKit configuration file into the Run action of the Xcode scheme of the iOS app, so that running the game from
# Xcode sells the products of that file (Products.storekit, written by `factoria export --platform ios` from factoria.json's
# platform catalog) with no App Store Connect, sandbox account or network. CMake's Xcode generator has no property for it,
# so build_ios.sh runs this script after configuring:
#
#   cmake -DPROJECT=<build>/FactorIA.xcodeproj -DSTOREKIT=<Products.storekit> [-DSCHEME=factoria_player] -P storekit_scheme.cmake
#
# The file is copied next to the .xcodeproj (so it follows the project when the build folder is moved) and the scheme
# references it as ../../Products.storekit, the way Xcode itself writes a configuration that lives beside the project.
# `xcrun simctl launch` and a release (App Store / TestFlight) build do not use it: the sandbox and the real store answer there.
if(NOT PROJECT OR NOT STOREKIT)
    message(FATAL_ERROR "storekit_scheme.cmake needs -DPROJECT=<.xcodeproj folder> and -DSTOREKIT=<file.storekit>.")
endif()
if(NOT SCHEME)
    set(SCHEME factoria_player)
endif()
if(NOT EXISTS "${STOREKIT}")
    message(FATAL_ERROR "The StoreKit configuration '${STOREKIT}' does not exist. Export the game again with `factoria export --platform ios`.")
endif()
set(scheme_file "${PROJECT}/xcshareddata/xcschemes/${SCHEME}.xcscheme")
if(NOT EXISTS "${scheme_file}")
    message(FATAL_ERROR "The scheme '${scheme_file}' does not exist: configure the project first (build_ios.sh does) with the Xcode generator.")
endif()

get_filename_component(file_name "${STOREKIT}" NAME)
get_filename_component(project_parent "${PROJECT}" DIRECTORY)
configure_file("${STOREKIT}" "${project_parent}/${file_name}" COPYONLY)

file(READ "${scheme_file}" scheme)
set(reference "<StoreKitConfigurationFileReference\n         identifier = \"../../${file_name}\">\n      </StoreKitConfigurationFileReference>\n")
if(scheme MATCHES "<StoreKitConfigurationFileReference")
    string(REGEX REPLACE "[ \t]*<StoreKitConfigurationFileReference[^>]*>[ \t\r\n]*</StoreKitConfigurationFileReference>[ \t]*\r?\n?"
           "      ${reference}" scheme "${scheme}")
elseif(scheme MATCHES "</LaunchAction>")
    string(REPLACE "</LaunchAction>" "      ${reference}   </LaunchAction>" scheme "${scheme}")
else()
    message(FATAL_ERROR "The scheme '${scheme_file}' has no LaunchAction to put the StoreKit configuration in. In Xcode: Product > Scheme > "
                        "Edit Scheme > Run > Options > StoreKit Configuration > ${file_name}.")
endif()
file(WRITE "${scheme_file}" "${scheme}")
message(STATUS "StoreKit: the '${SCHEME}' scheme sells the products of ${file_name}")
