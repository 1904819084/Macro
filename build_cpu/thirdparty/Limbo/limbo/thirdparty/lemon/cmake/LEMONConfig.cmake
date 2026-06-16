SET(LEMON_INCLUDE_DIR "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/install/include" CACHE PATH "LEMON include directory")
SET(LEMON_INCLUDE_DIRS "${LEMON_INCLUDE_DIR}")

IF(UNIX)
  SET(LEMON_LIB_NAME "libemon.a")
ELSEIF(WIN32)
  SET(LEMON_LIB_NAME "lemon.lib")
ENDIF(UNIX)

SET(LEMON_LIBRARY "/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/install/lib/${LEMON_LIB_NAME}" CACHE FILEPATH "LEMON library")
SET(LEMON_LIBRARIES "${LEMON_LIBRARY}")

MARK_AS_ADVANCED(LEMON_LIBRARY LEMON_INCLUDE_DIR)
