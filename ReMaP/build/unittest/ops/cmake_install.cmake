# Install script for directory: /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops

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
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/place_io_unittest/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/macro_legalize_unittest/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/greedy_legalize_unittest/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/abacus_legalize_unittest/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/global_swap_unittest/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/independent_set_matching_unittest/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/k_reorder_unittest/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/unittest/ops" TYPE FILE FILES
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/adjust_node_area_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/dct_electric_potential_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/dct_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/density_overflow_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/density_potential_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/draw_place_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/electric_potential_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/hpwl_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/logsumexp_wirelength_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/move_boundary_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/pin_pos_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/pin_utilization_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/pinrudy_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/rmst_wl_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/rudy_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/torch_fft_unittest.py"
    "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/unittest/ops/weighted_average_wirelength_unittest.py"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/build/unittest/ops/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
