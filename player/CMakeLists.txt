# factoria_player: the minimal runtime shipped inside exported games.
# Desktop: `factoria_player <project-dir>`; mobile builds embed the project
# data as app assets (see platforms/android and platforms/ios).
file(GLOB player_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
if(FA_PLATFORM STREQUAL "android")
    add_library(factoria_player SHARED ${player_srcs})
else()
    add_executable(factoria_player ${player_srcs})
endif()
target_link_libraries(factoria_player PRIVATE fa_runtime fa_warnings)
