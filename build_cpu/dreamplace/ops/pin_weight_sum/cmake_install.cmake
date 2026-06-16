# Install script for directory: /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/pin_weight_sum

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/install")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Library/Developer/CommandLineTools/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace/ops/pin_weight_sum" TYPE MODULE FILES "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pin_weight_sum/pws_cpp.cpython-39-darwin.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/pin_weight_sum/pws_cpp.cpython-39-darwin.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/pin_weight_sum/pws_cpp.cpython-39-darwin.so")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Library/Developer/CommandLineTools/usr/bin/strip" -x "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/pin_weight_sum/pws_cpp.cpython-39-darwin.so")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pin_weight_sum/CMakeFiles/pws_cpp.dir/install-cxx-module-bmi-Release.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace/ops/pin_weight_sum" TYPE FILE FILES
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/pin_weight_sum/__init__.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/pin_weight_sum/pin_weight_sum.py"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pin_weight_sum/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
