#
#   This file is part of Corrade.
#
#   Original authors — credit is appreciated but not required:
#
#       2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
#       2017, 2018, 2019, 2020, 2021, 2022
#           — Vladimír Vondruš <mosra@centrum.cz>
#
#   This is free and unencumbered software released into the public domain.
#
#   Anyone is free to copy, modify, publish, use, compile, sell, or distribute
#   this software, either in source code form or as a compiled binary, for any
#   purpose, commercial or non-commercial, and by any means.
#
#   In jurisdictions that recognize copyright laws, the author or authors of
#   this software dedicate any and all copyright interest in the software to
#   the public domain. We make this dedication for the benefit of the public
#   at large and to the detriment of our heirs and successors. We intend this
#   dedication to be an overt act of relinquishment in perpetuity of all
#   present and future rights to this software under copyright law.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
#   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

cmake_minimum_required(VERSION 3.4)

project(CorradePluginManagerExample2 CXX)

# plugin_name
set(plugin_name1 "Canary2")
set(plugin_name2 "Dog2")

# Add module path in case this is project root
if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../../../modules" ${CMAKE_MODULE_PATH})
endif()

find_package(Corrade REQUIRED PluginManager)
set_directory_properties(PROPERTIES CORRADE_USE_PEDANTIC_FLAGS ON)

# See _CORRADE_USE_NO_TARGET_CHECKS in Corrade's root CMakeLists
if(NOT _CORRADE_USE_NO_TARGET_CHECKS AND NOT TARGET Corrade::PluginManager)
message(FATAL_ERROR "The Corrade::PluginManager target, needed by corrade_add_plugin(), doesn't exist. Add the PluginManager component to your find_package() or enable CORRADE_WITH_PLUGINMANAGER if you have Corrade as a CMake subproject.")
endif()

if(CORRADE_TARGET_EMSCRIPTEN OR CORRADE_TARGET_WINDOWS_RT OR CORRADE_TARGET_IOS)
message(SEND_ERROR "corrade_add_plugin(): dynamic plugins are not available on this platform, use corrade_add_static_plugin() instead")
endif()


#--------------static----------------
set(PluginTest2_static_SRCS
    plugin.cpp
    Canary_static.cpp)

# Create static library and bring all needed options along
add_library(${plugin_name1} STATIC ${ARGN} ${PluginTest2_static_SRCS})
set_target_properties(${plugin_name1} PROPERTIES CORRADE_CXX_STANDARD 11)
target_compile_definitions(${plugin_name1} PRIVATE "CORRADE_STATIC_PLUGIN")
target_include_directories(${plugin_name1} PUBLIC $<TARGET_PROPERTY:Corrade::PluginManager,INTERFACE_INCLUDE_DIRECTORIES>)

set_target_properties(${plugin_name1} PROPERTIES DEBUG_POSTFIX "-d")


#--------------shared----------------
set(PluginTest2_shared_SRCS
    Dog_shared.cpp)
    
add_library(${plugin_name2} SHARED ${ARGN} ${PluginTest2_shared_SRCS})

set_target_properties(${plugin_name2} PROPERTIES CORRADE_CXX_STANDARD 11)
target_compile_definitions(${plugin_name2} PRIVATE "CORRADE_DYNAMIC_PLUGIN")
target_include_directories(${plugin_name2} PUBLIC $<TARGET_PROPERTY:Corrade::PluginManager,INTERFACE_INCLUDE_DIRECTORIES>)
target_link_libraries(${plugin_name2} PRIVATE Corrade::PluginManager)

# Add the executable test
add_executable(PluginTest2 main.cpp)
target_link_libraries(PluginTest2 PRIVATE ${plugin_name1} Corrade::PluginManager)
