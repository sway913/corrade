if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2022" call "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvarsall.bat" %PLATFORM% || exit /b
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2019" call "C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Auxiliary/Build/vcvarsall.bat" %PLATFORM% || exit /b
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2017" call "C:/Program Files (x86)/Microsoft Visual Studio/2017/Community/VC/Auxiliary/Build/vcvarsall.bat" %PLATFORM% || exit /b
if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2015" call "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/vcvarsall.bat" %PLATFORM% || exit /b
set PATH=%APPVEYOR_BUILD_FOLDER%\deps\bin;%PATH%

rem need to explicitly specify a 64-bit target, otherwise CMake+Ninja can't
rem figure that out -- https://gitlab.kitware.com/cmake/cmake/issues/16259
rem for TestSuite we need to enable exceptions explicitly with /EH as these are
rem currently disabled -- https://github.com/catchorg/Catch2/issues/1113
if "%COMPILER%" == "msvc-clang" if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2022" set COMPILER_EXTRA=-DCMAKE_CXX_COMPILER="C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/Llvm/bin/clang-cl.exe" -DCMAKE_LINKER="C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/Llvm/bin/lld-link.exe" -DCMAKE_CXX_FLAGS="-m64 /EHsc"
if "%COMPILER%" == "msvc-clang" if "%APPVEYOR_BUILD_WORKER_IMAGE%" == "Visual Studio 2019" set COMPILER_EXTRA=-DCMAKE_CXX_COMPILER="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/Llvm/bin/clang-cl.exe" -DCMAKE_LINKER="C:/Program Files (x86)/Microsoft Visual Studio/2019/Community/VC/Tools/Llvm/bin/lld-link.exe" -DCMAKE_CXX_FLAGS="-m64 /EHsc"

rem Build
mkdir build && cd build || exit /b
cmake .. ^
    -DCMAKE_BUILD_TYPE=%CONFIGURATION% ^
    -DCMAKE_INSTALL_PREFIX=%APPVEYOR_BUILD_FOLDER%/deps ^
    -DCORRADE_UTILITY_USE_ANSI_COLORS=%ANSI_COLORS% ^
    -DCORRADE_BUILD_STATIC=%BUILD_STATIC% ^
    %COMPILER_EXTRA% -G Ninja || exit /b
cmake --build . || exit /b

rem Test
set CORRADE_TEST_COLOR=ON
rem On Windows, if an assertion or other issue happens, A DIALOG WINDOWS POPS
rem UP FROM THE CONSOLE. And then, for fucks sake, IT WAITS ENDLESSLY FOR YOU
rem TO CLOSE IT!! Such behavior is utterly stupid in a non-interactive setting
rem such as on this very CI, so I'm setting a timeout to 60 seconds to avoid
rem the CI job being stuck for an hour if an assertion happens. CTest's default
rem timeout is somehow 10M seconds, which is as useful as nothing at all.
ctest -V --timeout 120 || exit /b

rem Test install, after running the tests as for them it shouldn't be needed
cmake --build . --target install || exit /b

rem Examples
cd %APPVEYOR_BUILD_FOLDER% || exit /b
mkdir build-examples && cd build-examples || exit /b
cmake ../src/examples ^
    -DCMAKE_BUILD_TYPE=%CONFIGURATION% ^
    -DCMAKE_PREFIX_PATH=%APPVEYOR_BUILD_FOLDER%/deps ^
    %COMPILER_EXTRA% -G Ninja || exit /b
cmake --build . || exit /b
