# This finder resolves the virtual BLAS package for sub-projects.
# It defers to the built host-blas, if available, otherwise, failing.
cmake_policy(PUSH)
cmake_policy(SET CMP0057 NEW)

if("OpenBLAS" IN_LIST THEROCK_PROVIDED_PACKAGES)
  cmake_policy(POP)
  message(STATUS "Resolving bundled host-blas library from super-project")
  find_package(OpenBLAS CONFIG REQUIRED)
  # See: https://cmake.org/cmake/help/latest/module/FindBLAS.html
  set(LAPACK_LINKER_FLAGS)
  set(LAPACK_LIBRARIES OpenBLAS::OpenBLAS)
  add_library(LAPACK::LAPACK ALIAS OpenBLAS::OpenBLAS)
  set(LAPACK95_LIBRARIES)
  set(LAPACK95_FOUND FALSE)
  set(LAPACK_FOUND TRUE)
else()
  cmake_policy(POP)
  set(LAPACK_FOUND FALSE)
endif()
