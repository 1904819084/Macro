# Install script for directory: /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops

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
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/utility/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/place_io/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/dct/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pin_pos/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/move_boundary/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/draw_place/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/density_map/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/density_overflow/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/density_potential/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/electric_potential/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/hpwl/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/weighted_average_wirelength/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/logsumexp_wirelength/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/fence_region/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/legality_check/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/macro_legalize/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/greedy_legalize/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/abacus_legalize/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/global_swap/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/independent_set_matching/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/k_reorder/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pin_utilization/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/rudy/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pinrudy/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/nctugr_binary/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/adjust_node_area/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/pin_weight_sum/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/timing/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/dreamplace/ops" TYPE FILE FILES "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/dreamplace/ops/__init__.py")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/build_cpu/dreamplace/ops/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
