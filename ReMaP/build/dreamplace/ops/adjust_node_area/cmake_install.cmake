# Install script for directory: /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/adjust_node_area

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
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area" TYPE MODULE FILES "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/ops/adjust_node_area/adjust_node_area_cpp.cpython-39-darwin.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area/adjust_node_area_cpp.cpython-39-darwin.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area/adjust_node_area_cpp.cpython-39-darwin.so")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Library/Developer/CommandLineTools/usr/bin/strip" -x "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area/adjust_node_area_cpp.cpython-39-darwin.so")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/ops/adjust_node_area/CMakeFiles/adjust_node_area_cpp.dir/install-cxx-module-bmi-Release.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area" TYPE MODULE FILES "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/ops/adjust_node_area/update_pin_offset_cpp.cpython-39-darwin.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area/update_pin_offset_cpp.cpython-39-darwin.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area/update_pin_offset_cpp.cpython-39-darwin.so")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/Library/Developer/CommandLineTools/usr/bin/strip" -x "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area/update_pin_offset_cpp.cpython-39-darwin.so")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/ops/adjust_node_area/CMakeFiles/update_pin_offset_cpp.dir/install-cxx-module-bmi-Release.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace/ops/adjust_node_area" TYPE FILE FILES
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/adjust_node_area/__init__.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/adjust_node_area/adjust_node_area.py"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/ops/adjust_node_area/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
