# NINJA GAIDEN Master Collection NM Plugin by Nozomi Miyamori
# is marked with CC0 1.0. This file is a part of NINJA GAIDEN
# Master Collection NM Plugin.

cmake_minimum_required(VERSION 3.20)
project(ngs2-nm-plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_OPTIMIZE_DEPENDENCIES on)
set(CMAKE_SHARED_MODULE_SUFFIX ".dll")

add_library(util INTERFACE)
target_include_directories(util INTERFACE src)

link_libraries(util)

add_library(core MODULE src/core/main.cpp)
set_property(TARGET core PROPERTY PREFIX "")
set_property(TARGET core PROPERTY OUTPUT_NAME "core")

add_library(steam-bugfixes MODULE src/steam-bugfixes/main.cpp)
add_library(loader MODULE src/loader/main.cpp)
add_library(effect MODULE src/effect/main.cpp)
add_library(combat MODULE src/combat/main.cpp)
set_property(TARGET
	steam-bugfixes
	loader
	effect
	combat
	PROPERTY PREFIX "nm")

install(TARGETS core DESTINATION plugin COMPONENT core-runtime)
install(TARGETS steam-bugfixes DESTINATION ./plugin)
install(TARGETS loader DESTINATION ./plugin)
install(TARGETS effect DESTINATION ./plugin)
install(TARGETS combat DESTINATION ./plugin)

# Unattended-session test harness (screenshots / command file / actor control).
add_library(lab MODULE src/lab/main.cpp)
set_property(TARGET lab PROPERTY PREFIX "ngs2")
target_link_libraries(lab d3d11 dxgi)
target_link_options(lab PRIVATE -static -static-libgcc -static-libstdc++)
target_compile_options(lab PRIVATE -O2)

# Second local player for Team Missions (docs/P2_CONTROL.md). Replaces the old NGS2Coop.dll stub.
add_library(coop MODULE src/coop/main.cpp src/coop/overlay.cpp src/coop/split.cpp src/coop/gametext.cpp src/coop/quickmenu.cpp)
set_property(TARGET coop PROPERTY PREFIX "")
set_property(TARGET coop PROPERTY OUTPUT_NAME "NGS2Coop")
target_link_libraries(coop d3d11 dxgi gdi32 ws2_32)
target_link_options(coop PRIVATE -static -static-libgcc -static-libstdc++)
target_compile_options(coop PRIVATE -O2 -Wall -Wextra)
