set(version "v3.31.6")

# Clean any stale/partial downloads from previous interrupted runs.
# Re-downloading is cheap (~120 KiB) and avoids cache corruption issues.
file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/cmake")
file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/modules.tar.gz")

# Recreate target directory
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cmake")

set(modules_tar "${CMAKE_CURRENT_BINARY_DIR}/modules.tar.gz")
set(cmake_modules "${CMAKE_CURRENT_BINARY_DIR}/cmake/Modules")

message(STATUS "Downloading CMake ${version} ExternalProject module support files...")

# Download the ExternalProject subdirectory tarball.
# -f: fail on HTTP errors
# -S: show errors even when -s is used
# -L: follow redirects
# --retry/--retry-delay: transient network resilience
execute_process(
    COMMAND curl -fSL --retry 3 --retry-delay 5
        "https://gitlab.kitware.com/cmake/cmake/-/archive/${version}/cmake-${version}.tar.gz?path=Modules/ExternalProject"
        -o "${modules_tar}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    RESULT_VARIABLE curl_modules_result
    ERROR_VARIABLE curl_modules_error
)
if(NOT curl_modules_result EQUAL 0)
    message(FATAL_ERROR "Failed to download CMake ExternalProject support tarball from gitlab.kitware.com (curl exited with ${curl_modules_result}): ${curl_modules_error}")
endif()

if(NOT EXISTS "${modules_tar}")
    message(FATAL_ERROR "CMake ExternalProject support tarball was not created after download")
endif()

# Extract tarball. The archive has top-level directory cmake-<version>/; strip it.
execute_process(
    COMMAND tar -C "${CMAKE_CURRENT_BINARY_DIR}/cmake" --strip-components=1 -xf "${modules_tar}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    RESULT_VARIABLE tar_result
    ERROR_VARIABLE tar_error
)
if(NOT tar_result EQUAL 0)
    message(FATAL_ERROR "Failed to extract CMake ExternalProject support tarball: ${tar_error}")
endif()

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/cmake/Modules/ExternalProject/gitclone.cmake.in")
    message(FATAL_ERROR "Extracted CMake ExternalProject support files are missing expected files")
endif()

message(STATUS "Downloading CMake ${version} ExternalProject.cmake...")

# Download the top-level ExternalProject.cmake
file(MAKE_DIRECTORY "${cmake_modules}")

execute_process(
    COMMAND curl -fSL --retry 3 --retry-delay 5
        "https://gitlab.kitware.com/cmake/cmake/-/raw/${version}/Modules/ExternalProject.cmake"
        -o "${cmake_modules}/ExternalProject.cmake"
    WORKING_DIRECTORY "${cmake_modules}"
    RESULT_VARIABLE curl_ep_result
    ERROR_VARIABLE curl_ep_error
)
if(NOT curl_ep_result EQUAL 0)
    message(FATAL_ERROR "Failed to download CMake ExternalProject.cmake from gitlab.kitware.com (curl exited with ${curl_ep_result}): ${curl_ep_error}")
endif()

if(NOT EXISTS "${cmake_modules}/ExternalProject.cmake")
    message(FATAL_ERROR "CMake ExternalProject.cmake was not created after download")
endif()

# Apply local patches for GIT_CLONE_FLAGS / GIT_CLONE_POST_COMMAND / GIT_RESET support.
execute_process(
    COMMAND patch -p1 -i "${CMAKE_CURRENT_SOURCE_DIR}/packages/cmake-0001-ExternalProject-changes.patch"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cmake"
    RESULT_VARIABLE patch_result
    ERROR_VARIABLE patch_error
)
if(NOT patch_result EQUAL 0)
    message(FATAL_ERROR "Failed to patch CMake ExternalProject module: ${patch_error}")
endif()

include("${cmake_modules}/ExternalProject.cmake")
