# Install script for directory: /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace

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

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/ops/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace" TYPE FILE FILES
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/BasicPlace.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/Cluster.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/EvalMetrics.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/NesterovAcceleratedGradientOptimizer.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/NonLinearPlace.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/Params.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/PlaceDB.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/PlaceObj.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/Placer.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/Plot.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/Timer.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/__init__.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/params.json"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/process_def.py"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/dreamplace/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
