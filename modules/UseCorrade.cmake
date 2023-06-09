
# (the blank line is here so CMake doesn't generate documentation from it)

#
#   This file is part of Corrade.
#
#   Copyright © 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
#               2017, 2018, 2019, 2020, 2021, 2022
#             Vladimír Vondruš <mosra@centrum.cz>
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included
#   in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#

# Already included, nothing to do
if(_CORRADE_USE_INCLUDED)
    return()
endif()

# Compiler identification. Unlike other CORRADE_TARGET_* variables it's not
# saved/restored from configure.h as the compiler used to compile Corrade may
# differ from the compiler used to link to it.
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CORRADE_TARGET_GCC 1)
endif()
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CORRADE_TARGET_CLANG 1)
    if(CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
        set(CORRADE_TARGET_CLANG_CL 1)
        set(CORRADE_TARGET_MSVC 1)
    else()
        set(CORRADE_TARGET_GCC 1)
    endif()
endif()
# With older Emscripten (or CMake?) versions the compiler is detected as
# "unknown" instead of Clang. Force the compiler resolution in that case.
# TODO: figure out why
if(CORRADE_TARGET_EMSCRIPTEN)
    set(CORRADE_TARGET_GCC 1)
    set(CORRADE_TARGET_CLANG 1)
endif()
if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
    set(CORRADE_TARGET_GCC 1)
    set(CORRADE_TARGET_CLANG 1)
    set(CORRADE_TARGET_APPLE_CLANG 1)
endif()
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(CORRADE_TARGET_MSVC 1)
endif()
if(MINGW)
    set(CORRADE_TARGET_MINGW 1)
endif()

# Check compiler version
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Don't allow to use compilers older than what compatibility mode allows
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.8.1")
        message(FATAL_ERROR "Corrade cannot be used with GCC < 4.8.1. Sorry.")
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # Don't allow to use compilers older than what compatibility mode allows
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.0")
        message(FATAL_ERROR "Corrade cannot be used with MSVC < 2015. Sorry.")
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.10")
        if(NOT CORRADE_MSVC2015_COMPATIBILITY)
            message(FATAL_ERROR "To use Corrade with MSVC 2015, build it with CORRADE_MSVC2015_COMPATIBILITY enabled")
        endif()
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.20")
        if(NOT CORRADE_MSVC2017_COMPATIBILITY)
            message(FATAL_ERROR "To use Corrade with MSVC 2017, build it with CORRADE_MSVC2017_COMPATIBILITY enabled")
        endif()
    endif()

    # Don't allow to use compiler newer than what compatibility mode allows
    if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.10")
        if(CORRADE_MSVC2015_COMPATIBILITY)
            message(FATAL_ERROR "MSVC >= 2017 cannot be used if Corrade is built with CORRADE_MSVC2015_COMPATIBILITY")
        endif()
    elseif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.20")
        if(CORRADE_MSVC2017_COMPATIBILITY)
            message(FATAL_ERROR "MSVC >= 2019 cannot be used if Corrade is built with CORRADE_MSVC2017_COMPATIBILITY")
        endif()
    endif()
endif()

# GCC/Clang-specific compiler flags
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR (CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang" AND NOT CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC") OR CORRADE_TARGET_EMSCRIPTEN)
    set(CORRADE_PEDANTIC_COMPILER_OPTIONS
        "-Wall" "-Wextra"
        "$<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>:-Wold-style-cast>"
        "-Winit-self"
        "-Werror=return-type"
        "-Wmissing-declarations"
        # -Wpedantic is since 4.8, until then only -pedantic (which doesn't
        # have any -Wno-pedantic or a way to disable it for a particular line)
        "-Wpedantic"
        # Needs to have both, otherwise Clang's linker on macOS complains that
        # "direct access in function [...] to global weak symbol [...] means the
        # weak symbol cannot be overridden at runtime. This was likely caused
        # by different translation units being compiled with different
        # visibility settings." See also various google results for the above
        # message.
        "-fvisibility=hidden" "-fvisibility-inlines-hidden"
        # A lot of functionality relies on aliased pointers, such as the whole
        # StridedArrayView. Given numerous other libraries including stb_image
        # *and the Linux kernel itself* disable this as well, I see no reason
        # for needless suffering either. I don't remember strict aliasing to
        # ever help with optimizing anything, plus it was disabled for the
        # whole of Magnum since December 2013 already:
        #   https://github.com/mosra/magnum/commit/f373b6518e0b1fa3e4d0ffb19f77e80a8a56484c
        # So let's just make it official and disable it for everything,
        # everywhere, forever.
        "-fno-strict-aliasing")

    # Some flags are not yet supported everywhere
    # TODO: do this with check_c_compiler_flags()
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        list(APPEND CORRADE_PEDANTIC_COMPILER_OPTIONS
            "$<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>:-Wzero-as-null-pointer-constant>"

            # TODO: enable when this gets to Clang (not in 3.9, but in master
            # since https://github.com/llvm-mirror/clang/commit/0a022661c797356e9c28e4999b6ec3881361371e)
            "-Wdouble-promotion")

        # GCC 4.8 doesn't like when structs are initialized using just {} and
        # because we use that a lot, the output gets extremely noisy. Disable
        # the warning altogether there.
        if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "5.0")
            list(APPEND CORRADE_PEDANTIC_COMPILER_OPTIONS "-Wno-missing-field-initializers")
        endif()
    endif()

    if(CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang" OR CORRADE_TARGET_EMSCRIPTEN)
        list(APPEND CORRADE_PEDANTIC_COMPILER_OPTIONS
            # Clang's -Wmissing-declarations does something else and the
            # behavior we want is under -Wmissing-prototypes. See
            # https://llvm.org/bugs/show_bug.cgi?id=16286.
            "-Wmissing-prototypes"

            # Fixing it in all places would add too much noise to the code.
            "-Wno-shorten-64-to-32")

        list(APPEND CORRADE_PEDANTIC_TEST_COMPILER_OPTIONS
            # Unlike GCC, -Wunused-function (which is enabled through -Wall)
            # doesn't fire for member functions, it's controlled separately
            "-Wunused-member-function"
            # This is implicitly enabled by the above and causes lots of
            # warnings for e.g. move constructors, so disabling
            "-Wno-unneeded-member-function")
    endif()

# MSVC-specific compiler flags
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
    set(CORRADE_PEDANTIC_COMPILER_OPTIONS
        # Enable extra warnings (similar to -Wall)
        "/W4"

        # "conditional expression is constant", especially when a template
        # argument is passed to an if, which happens mainly in tests but
        # sometimes also in recursive constexpr functions. As I can't use if
        # constexpr in C++11 code, there's not really much I can do.
        "/wd4127"

        # "needs to have dll-interface to be used by clients", as the fix for
        # that would effectively prevent using STL completely.
        "/wd4251"

        "/wd4819"

        # "conversion from '<bigger int type>' to '<smaller int type>'",
        # "conversion from 'size_t' to '<smaller int type>', possible loss of
        # data", fixing this would add too much noise. Equivalent to
        # -Wshorten-64-to-32 on Clang.
        "/wd4244"
        "/wd4267"

        # "structure was padded due to alignment specifier". YES. THAT'S
        # EXACTLY AS INTENDED.
        "/wd4324"

        # "new behavior: elements of array will be default initialized".
        # YES. YES I KNOW WHAT I'M DOING.
        "/wd4351"

        # "previous versions of the compiler did not override when parameters
        # only differed by const/volatile qualifiers". Okay. So you had bugs.
        # And?
        "/wd4373"

        # "declaration of 'foo' hides class member". I use this a lot in
        # constructor arguments, `Class(int foo): foo{foo} {}` and adding some
        # underscores to mitigate this would not be pretty. OTOH, "C4456:
        # declaration of 'foo' hides previous local declaration" points to a
        # valid issue that I should get rid of.
        "/wd4458"

        # "default constructor could not be generated/can never be
        # instantiated". Apparently it can.
        "/wd4510"
        "/wd4610"

        # "assignment operator could not be generated". Do I want one? NO I
        # DON'T.
        "/wd4512"

        # "no suitable definition for explicit template instantiation". No. The
        # problem is apparently that I'm having the definitions in *.cpp file
        # and instantiating them explicitly. Common practice here.
        "/wd4661"

        # "unreachable code". *Every* assertion has return after std::abort().
        # So?
        "/wd4702"

        # "assignment within conditional expression". It's not my problem that
        # it doesn't get the hint with extra parentheses (`if((a = b))`).
        "/wd4706"

        # "forcing value to bool 'true' or 'false' (performance warning)". So
        # what. I won't wrap everything in bool(). This is a _language feature_,
        # dammit.
        "/wd4800"

        # "dllexport and extern are incompatible on an explicit instantiation".
        # Why the error is emitted only on classes? Functions are okay with
        # dllexport extern?!
        "/wd4910")
    set(CORRADE_PEDANTIC_COMPILER_DEFINITIONS
        # Disabling warning for not using "secure-but-not-standard" STL algos
        "_CRT_SECURE_NO_WARNINGS" "_SCL_SECURE_NO_WARNINGS")
endif()

if(CORRADE_TARGET_CLANG_CL)
    list(APPEND CORRADE_PEDANTIC_COMPILER_OPTIONS
        # See Utility::Path::libraryLocation() for details
        "-Wno-microsoft-cast")
endif()

# Compiler flags to undo horrible crimes done by windows.h, common for both
# MSVC and MinGW
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC" OR MINGW)
    list(APPEND CORRADE_PEDANTIC_COMPILER_DEFINITIONS
        # Disabling all minmax nonsense macros coming from windows.h
        "NOMINMAX"

        # Disabling GDI and other mud in windows.h (which in turn fixes the
        # dreaded #define interface struct UNLESS something includes the cursed
        # headers such as shlwapi.h directly -- libjpeg does that, for
        # instance).
        "WIN32_LEAN_AND_MEAN")
endif()

define_property(TARGET PROPERTY CORRADE_CXX_STANDARD INHERITED
    BRIEF_DOCS "C++ standard to require for given target"
    FULL_DOCS "Sets compiler-specific flags to enable C++11 or later standard
        when building given target or targets in given directory. Set in
        combination with INTERFACE_CORRADE_CXX_STANDARD to force the standard
        also on users of given target.")
define_property(TARGET PROPERTY INTERFACE_CORRADE_CXX_STANDARD INHERITED
    BRIEF_DOCS "C++ standard to require for users of given target"
    FULL_DOCS "Sets compiler-specific flags to enable C++11 or later standard
        when using given target or targets in given directory.")
define_property(TARGET PROPERTY CORRADE_USE_PEDANTIC_FLAGS INHERITED
    BRIEF_DOCS "Use pedantic compiler/linker flags"
    FULL_DOCS "Enables additional pedantic C, C++ and linker flags on given
        targets or directories.")

# Enable C++11/14/17/2a on GCC/Clang if CORRADE_CXX_STANDARD is set. Does
# nothing in case the user put "-std=" in CMAKE_CXX_FLAGS.
if((CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR (CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang" AND NOT CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC") OR CORRADE_TARGET_EMSCRIPTEN) AND NOT CMAKE_CXX_FLAGS MATCHES "-std=")
    set(CORRADE_CXX11_STANDARD_FLAG "-std=c++11")
    if((CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.9) OR ((CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang" OR CORRADE_TARGET_EMSCRIPTEN) AND NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.5))
        set(CORRADE_CXX14_STANDARD_FLAG "-std=c++14")
    else()
        set(CORRADE_CXX14_STANDARD_FLAG "-std=c++1y")
    endif()
    # TODO: change to C++17 when compiler support is widespread enough
    set(CORRADE_CXX17_STANDARD_FLAG "-std=c++1z")
    set(CORRADE_CXX20_STANDARD_FLAG "-std=c++2a")
endif()

# Enable C++14/17/2a on MSVC if CORRADE_CXX_STANDARD is set. C++11 is present
# implicitly, 14, 17 and 20 has to be enabled through a flag. Does nothing in
# case the user put "/std:" or "-std:" in CMAKE_CXX_FLAGS.
if((CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC") AND NOT CMAKE_CXX_FLAGS MATCHES "[-/]std:")
    set(CORRADE_CXX14_STANDARD_FLAG "/std:c++14")
    set(CORRADE_CXX17_STANDARD_FLAG "/std:c++17")
    # TODO: change to c++20? when such flag appears
    # https://docs.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version?view=vs-2019
    set(CORRADE_CXX20_STANDARD_FLAG "/std:c++latest")
endif()

# Finally, in order to avoid clashes with builtin CMake features, we won't add
# the standard flag in case the CXX_STANDARD property is present. Additionally,
# since CMake 3.15, the cxx_std_14 compile feature doesn't result in any flag
# being added to compiler command-line if C++14 is a default on given compiler
# (such as GCC 6 and up). That unfortunately means ours default flag (-std=c++11)
# gets set, making it look like the COMPILE_FEATURES didn't work at all. To
# circumvent that, the CORRADE_CXX_STANDARD isn't set if anything from
# COMPILE_FEATURES is present either. It doesn't cover adding flags using
# target_compile_options(), though.
set(_CORRADE_CXX_STANDARD_ONLY_IF_NOT_ALREADY_SET
    "$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>,$<NOT:$<BOOL:$<TARGET_PROPERTY:CXX_STANDARD>>>,$<NOT:$<BOOL:$<TARGET_PROPERTY:COMPILE_FEATURES>>>")
foreach(_standard 11 14 17 20)
    if(CORRADE_CXX${_standard}_STANDARD_FLAG)
        set_property(DIRECTORY APPEND PROPERTY COMPILE_OPTIONS
            "$<$<AND:${_CORRADE_CXX_STANDARD_ONLY_IF_NOT_ALREADY_SET},$<STREQUAL:$<TARGET_PROPERTY:CORRADE_CXX_STANDARD>,${_standard}>>:${CORRADE_CXX${_standard}_STANDARD_FLAG}>")
    endif()
endforeach()

# On-demand pedantic compiler flags
set_property(DIRECTORY APPEND PROPERTY COMPILE_OPTIONS "$<$<BOOL:$<TARGET_PROPERTY:CORRADE_USE_PEDANTIC_FLAGS>>:${CORRADE_PEDANTIC_COMPILER_OPTIONS}>")
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS "$<$<BOOL:$<TARGET_PROPERTY:CORRADE_USE_PEDANTIC_FLAGS>>:${CORRADE_PEDANTIC_COMPILER_DEFINITIONS}>")

# Provide a way to distinguish between debug and release builds via
# preprocessor define
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS "$<$<CONFIG:Debug>:CORRADE_IS_DEBUG_BUILD>")

if(CORRADE_TESTSUITE_TARGET_XCTEST)
    find_package(XCTest)

    # Workaround for CMake iOS generator expression bug, see below
    if(CORRADE_TARGET_IOS)
        if(CMAKE_OSX_SYSROOT MATCHES "iPhoneOS")
            set(_CORRADE_EFFECTIVE_PLATFORM_NAME "-iphoneos")
        elseif(CMAKE_OSX_SYSROOT MATCHES "iPhoneSimulator")
            set(_CORRADE_EFFECTIVE_PLATFORM_NAME "-iphonesimulator")
        endif()
    endif()
endif()

if(CORRADE_TARGET_IOS AND NOT CORRADE_TESTSUITE_TARGET_XCTEST)
    set(CORRADE_TESTSUITE_BUNDLE_IDENTIFIER_PREFIX ${PROJECT_NAME} CACHE STRING
        "Bundle identifier prefix for tests ran on iOS device")
endif()

function(corrade_add_resource name input)
    foreach(arg ${ARGN})
        if(arg STREQUAL SINGLE)
            set(single_file --single)
        endif()
    endforeach()

    # See _CORRADE_USE_NO_TARGET_CHECKS in Corrade's root CMakeLists
    if(NOT _CORRADE_USE_NO_TARGET_CHECKS AND NOT TARGET Corrade::rc)
        if(CMAKE_CROSSCOMPILING)
            message(FATAL_ERROR "The Corrade::rc target, needed by corrade_add_resource() and corrade_add_static_plugin(), doesn't exist. Build a native version, either make it available through PATH or pass its location to CMake using the CORRADE_RC_EXECUTABLE option, and add the Utility / rc component to your find_package(Corrade).")
        else()
            message(FATAL_ERROR "The Corrade::rc target, needed by corrade_add_resource() and corrade_add_static_plugin(), doesn't exist. Add the Utility / rc component to your find_package(Corrade) or enable CORRADE_WITH_UTILITY / CORRADE_WITH_RC if you have Corrade as a CMake subproject.")
        endif()
    endif()

    # Parse dependencies from the file, unless it's a single file
    if(NOT single_file)
        set(dependencies )
        set(filenameRegex "^[ \t]*filename[ \t]*=(.+)$")
        get_filename_component(configurationFilePath ${input} PATH)

        file(STRINGS "${input}" filenames REGEX ${filenameRegex} ENCODING UTF-8)
        foreach(filename ${filenames})
            # Get the filename together with leading/trailing whitespace and quotes
            # from the file line
            string(REGEX REPLACE ${filenameRegex} "\\1" filename "${filename}")
            # Strip leading/trailing whitespace
            string(STRIP "${filename}" filename)
            # If it's quoted (for example because the filename itself has spaces),
            # remove the quotes
            string(REGEX REPLACE "^\"([^\"]+)\"$" "\\1" filename "${filename}")
            if(NOT IS_ABSOLUTE "${filename}" AND configurationFilePath)
                set(filename "${configurationFilePath}/${filename}")
            endif()
            list(APPEND dependencies "${filename}")
        endforeach()

        # Force IDEs display also the resource files in project view
        add_custom_target(${name}-dependencies SOURCES ${dependencies})
        list(APPEND dependencies ${name}-dependencies)
    endif()

    # Output file name
    set(out "${CMAKE_CURRENT_BINARY_DIR}/resource_${name}.cpp")

    # Tell CMake to re-run and update the dependency list when the resource
    # list file changes (otherwise it parses the file only during the explicit
    # configure step and never again, thus additions/deletions are not
    # recognized automatically)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${input})

    # Run command
    add_custom_command(
        OUTPUT "${out}"
        COMMAND Corrade::rc ${single_file} ${name} "${input}" "${out}"
        DEPENDS Corrade::rc ${input} ${dependencies}
        COMMENT "Compiling data resource file ${out}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

    # Save output filename
    set(${name} "${out}" PARENT_SCOPE)
endfunction()

function(corrade_add_plugin plugin_name debug_install_dirs release_install_dirs metadata_file)
    # See _CORRADE_USE_NO_TARGET_CHECKS in Corrade's root CMakeLists
    if(NOT _CORRADE_USE_NO_TARGET_CHECKS AND NOT TARGET Corrade::PluginManager)
        message(FATAL_ERROR "The Corrade::PluginManager target, needed by corrade_add_plugin(), doesn't exist. Add the PluginManager component to your find_package() or enable CORRADE_WITH_PLUGINMANAGER if you have Corrade as a CMake subproject.")
    endif()

    if(CORRADE_TARGET_EMSCRIPTEN OR CORRADE_TARGET_WINDOWS_RT OR CORRADE_TARGET_IOS)
        message(SEND_ERROR "corrade_add_plugin(): dynamic plugins are not available on this platform, use corrade_add_static_plugin() instead")
    endif()

    # Populate {debug,release}_{binary,library,conf}_install_dir variables
    if(NOT debug_install_dirs STREQUAL CMAKE_CURRENT_BINARY_DIR)
        list(LENGTH debug_install_dirs debug_install_dir_count)
        list(LENGTH release_install_dirs release_install_dir_count)
        if(NOT debug_install_dir_count EQUAL release_install_dir_count)
            message(FATAL_ERROR "corrade_add_plugin(): either none or both install dirs must contain binary location")
        elseif(debug_install_dir_count EQUAL 1)
            set(debug_binary_install_dir ${debug_install_dirs})
            set(debug_library_install_dir ${debug_install_dirs})
            set(release_binary_install_dir ${release_install_dirs})
            set(release_library_install_dir ${release_install_dirs})
        elseif(debug_install_dir_count EQUAL 2)
            list(GET debug_install_dirs 0 debug_binary_install_dir)
            list(GET debug_install_dirs 1 debug_library_install_dir)
            list(GET release_install_dirs 0 release_binary_install_dir)
            list(GET release_install_dirs 1 release_library_install_dir)
        else()
            message(FATAL_ERROR "corrade_add_plugin(): install dirs must contain either just library location or both binary and library location")
        endif()

        if(CORRADE_TARGET_WINDOWS)
            set(debug_conf_install_dir ${debug_binary_install_dir})
            set(release_conf_install_dir ${release_binary_install_dir})
        else()
            set(debug_conf_install_dir ${debug_library_install_dir})
            set(release_conf_install_dir ${release_library_install_dir})
        endif()
    endif()

    # Create dynamic library and bring all needed options along. On Windows a
    # DLL cannot have undefined references, so we need to link against all its
    # dependencies *at compile time*, as opposed to runtime like in all sane
    # systems. But when using add_library(MODULE), CMake disallows linking
    # MODULEs to MODULEs (when dealing with inter-plugin dependencies, for
    # example) -- probably because, on Windows, creating a MODULE doesn't
    # create the corresponding import lib for it. So we work around that by
    # using SHARED on Windows.
    if(CORRADE_TARGET_WINDOWS)
        add_library(${plugin_name} SHARED ${ARGN})
    else()
        add_library(${plugin_name} MODULE ${ARGN})
    endif()
    set_target_properties(${plugin_name} PROPERTIES CORRADE_CXX_STANDARD 11)
    target_compile_definitions(${plugin_name} PRIVATE "CORRADE_DYNAMIC_PLUGIN")
    target_include_directories(${plugin_name} PUBLIC $<TARGET_PROPERTY:Corrade::PluginManager,INTERFACE_INCLUDE_DIRECTORIES>)

    # Plugins don't have any prefix (e.g. 'lib' on Linux)
    set_target_properties(${plugin_name} PROPERTIES PREFIX "")

    # Enable incremental linking on the Mac macOS
    if(CORRADE_TARGET_APPLE)
        set_target_properties(${plugin_name} PROPERTIES
            LINK_FLAGS "-undefined dynamic_lookup")
    endif()

    # Force IDEs display also the resource files in project view
    if(metadata_file)
        get_filename_component(metadata_file_suffix ${metadata_file} EXT)
        add_custom_target(${plugin_name}-metadata SOURCES ${metadata_file})

        # Copy metadata next to the binary so tests and CMake subprojects can
        # use it as well
        add_custom_command(TARGET ${plugin_name} POST_BUILD
            # This would be nice to Ninja, but BYPRODUCTS don't support generator
            # expressions right now (last checked: CMake 3.16)
            #BYPRODUCTS $<TARGET_FILE_DIR:${plugin_name}>/${plugin_name}${metadata_file_suffix}
            COMMAND ${CMAKE_COMMAND} -E copy ${metadata_file} $<TARGET_FILE_DIR:${plugin_name}>/${plugin_name}${metadata_file_suffix}
            DEPENDS ${metadata_file} ${name}-metadata
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    # Install it somewhere, unless that's explicitly not wanted
    if(NOT debug_install_dirs STREQUAL CMAKE_CURRENT_BINARY_DIR)
        # CONFIGURATIONS must be first in order to not be ignored when having
        # multiple destinations.
        # https://gitlab.kitware.com/cmake/cmake/issues/16361
        install(TARGETS ${plugin_name}
            CONFIGURATIONS Debug
            RUNTIME DESTINATION ${debug_binary_install_dir}
            LIBRARY DESTINATION ${debug_library_install_dir}
            ARCHIVE DESTINATION ${debug_library_install_dir})
        install(TARGETS ${plugin_name}
            CONFIGURATIONS "" None Release RelWithDebInfo MinSizeRel
            RUNTIME DESTINATION ${release_binary_install_dir}
            LIBRARY DESTINATION ${release_library_install_dir}
            ARCHIVE DESTINATION ${release_library_install_dir})
        if(metadata_file)
            install(FILES ${metadata_file} DESTINATION ${debug_conf_install_dir}
                RENAME "${plugin_name}${metadata_file_suffix}"
                CONFIGURATIONS Debug)
            install(FILES ${metadata_file} DESTINATION ${release_conf_install_dir}
                RENAME "${plugin_name}${metadata_file_suffix}"
                CONFIGURATIONS "" None Release RelWithDebInfo MinSizeRel)
        endif()
    endif()
endfunction()

function(corrade_add_static_plugin plugin_name install_dirs metadata_file)
    # See _CORRADE_USE_NO_TARGET_CHECKS in Corrade's root CMakeLists
    if(NOT _CORRADE_USE_NO_TARGET_CHECKS AND NOT TARGET Corrade::PluginManager)
        message(FATAL_ERROR "The Corrade::PluginManager target, needed by corrade_add_static_plugin(), doesn't exist. Add the PluginManager component to your find_package() or enable CORRADE_WITH_PLUGINMANAGER if you have Corrade as a CMake subproject.")
    endif()

    # Populate library_install_dir variable
    list(LENGTH install_dirs install_dir_count)
    if(install_dir_count EQUAL 1)
        set(library_install_dir ${install_dirs})
    elseif(install_dir_count EQUAL 2)
        list(GET install_dirs 1 library_install_dir)
    else()
        message(FATAL_ERROR "corrade_add_static_plugin(): install dir must contain either just library location or both library and binary location")
    endif()

    # Compile resources. If the metadata file is disabled, the resource is
    # empty.
    set(resource_out ${CMAKE_CURRENT_BINARY_DIR}/resource_${plugin_name}.cpp)
    if(metadata_file)
        add_custom_command(
            OUTPUT ${resource_out}
            COMMAND Corrade::rc ${plugin_name} --single ${metadata_file} ${resource_out}
            DEPENDS Corrade::rc ${metadata_file}
            COMMENT "Compiling static plugin metadata file ${resource_out}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    else()
        set(metadata_file ${CMAKE_CURRENT_BINARY_DIR}/${plugin_name}-empty.conf)
        add_custom_command(
            OUTPUT ${resource_out}
            COMMAND ${CMAKE_COMMAND} -E touch ${metadata_file}
            COMMAND Corrade::rc ${plugin_name} --single ${metadata_file} ${resource_out}
            DEPENDS Corrade::rc
            COMMENT "Compiling static plugin metadata file ${resource_out}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    # Create static library and bring all needed options along
    add_library(${plugin_name} STATIC ${ARGN} ${resource_out})
    set_target_properties(${plugin_name} PROPERTIES CORRADE_CXX_STANDARD 11)
    target_compile_definitions(${plugin_name} PRIVATE "CORRADE_STATIC_PLUGIN")
    target_include_directories(${plugin_name} PUBLIC $<TARGET_PROPERTY:Corrade::PluginManager,INTERFACE_INCLUDE_DIRECTORIES>)

    set_target_properties(${plugin_name} PROPERTIES DEBUG_POSTFIX "-d")

    # Install, if not into the same place
    if(NOT install_dirs STREQUAL CMAKE_CURRENT_BINARY_DIR)
        install(TARGETS ${plugin_name} DESTINATION ${library_install_dir})
    endif()
endfunction()

if(CORRADE_TARGET_WINDOWS)
function(corrade_find_dlls_for_libs result)
    set(dlls )
    foreach(lib ${ARGN})
        get_filename_component(lib_dir ${lib} DIRECTORY)
        get_filename_component(lib_name ${lib} NAME_WE)
        find_file(CORRADE_DLL_FOR_${lib_name} ${lib_name}.dll HINTS ${lib_dir}/../bin)
        list(APPEND dlls ${CORRADE_DLL_FOR_${lib_name}})
    endforeach()
    set(${result} ${dlls} PARENT_SCOPE)
endfunction()
endif()

set(_CORRADE_USE_INCLUDED TRUE)
