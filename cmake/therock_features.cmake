# therock_features.cmake
# Registry of features that can be enabled/disabled when building TheRock.
# In this context, "feature" can refer to either a top-level component/project
# or some optional configuration of it (typically as "project_feature").
# Features can have dependencies, which are a superset of the project
# dependencies and must be kept rationalized by hand.
#
# Each feature results in the following changes to the caller scope:
#   THEROCK_ENABLE_${feature_name}: boolean of whether enabled/disabled
#   THEROCK_REQUIRES_${feature_name}: List of features that are required to
#     be enabled for this feature
#   THEROCK_ALL_FEATURES: Added to this global list of features.
#
# A feature is enabled by default unless if the GROUP keyword is specified.
# In this case, it's default state is dependent on THEROCK_ENABLE_${group}.

function(therock_add_feature feature_name)
  cmake_parse_arguments(PARSE_ARGV 1 ARG
    ""
    "DEFAULT;GROUP;DESCRIPTION"
    "REQUIRES"
  )

  set(_default_enabled ON)
  if(ARG_GROUP)
    if(NOT "${THEROCK_ENABLE_${ARG_GROUP}}")
      set(_default_enabled OFF)
    endif()
  endif()
  if(THEROCK_RESET_FEATURES)
    set(_force "FORCE")
  endif()

  # Validate.
  if("${feature_name}" IN_LIST THEROCK_ALL_FEATURES)
    message(FATAL_ERROR "CMake feature already defined: ${feature_name}")
  endif()
  foreach(require ${ARG_REQUIRES})
    if(NOT DEFINED THEROCK_ENABLE_${require})
      message(FATAL_ERROR "CMake feature order error: ${feature_name} requires ${require} which was not defined first")
    endif()
  endforeach()

  # Set up the cache option and inject the effective value into the parent
  # scope.
  set(THEROCK_ENABLE_${feature_name} ${_default_enabled} CACHE BOOL "${ARG_DESCRIPTION}" ${_force})
  set(_actual $CACHE{THEROCK_ENABLE_${feature_name}})
  set(THEROCK_ENABLE_${feature_name} "${_actual}" PARENT_SCOPE)
  set(THEROCK_REQUIRES_${feature_name} ${ARG_REQUIRES} PARENT_SCOPE)
  set(_all_features ${THEROCK_ALL_FEATURES})
  list(APPEND _all_features "${feature_name}")
  set(THEROCK_ALL_FEATURES ${_all_features} PARENT_SCOPE)
endfunction()

function(therock_finalize_features)
  # Force enable any features required of an enabled feature.
  # These are processed in reverse declaration order, which ensures a DAG.
  set(all_features_reversed ${THEROCK_ALL_FEATURES})
  list(REVERSE all_features_reversed)
  set(_implicit_features)
  foreach(feature_name ${all_features_reversed})
    if(THEROCK_ENABLE_${feature_name})
      foreach(require ${THEROCK_REQUIRES_${feature_name}})
        if(NOT THEROCK_ENABLE_${require})
          set(THEROCK_ENABLE_${require} ON PARENT_SCOPE)
          set(THEROCK_ENABLE_${require} ON)
          list(APPEND _implicit_features ${require})
        endif()
      endforeach()
    endif()
  endforeach()

  if(_implicit_features)
    list(REMOVE_DUPLICATES _implicit_features)
    list(JOIN _implicit_features " " _implicit_features_spaces)
    message(STATUS "Implicitly enabled features: ${_implicit_features_spaces}")
  endif()
endfunction()

function(therock_report_features)
  # And report.
  message(STATUS "Enabled features:")
  set(_available_list)
  foreach(feature_name ${THEROCK_ALL_FEATURES})
    if(THEROCK_ENABLE_${feature_name})
      message(STATUS "  * ${feature_name} (-DTHEROCK_ENABLE_${feature_name}=ON)")
    else()
      list(APPEND _available_list "${feature_name}")
    endif()
  endforeach()
  if(_available_list)
    message(STATUS "Disabled features:")
    foreach(feature_name ${_available_list})
      message(STATUS "  * ${feature_name} (-DTHEROCK_ENABLE_${feature_name}=OFF)")
    endforeach()
  endif()

  # Reset the force disable flag.
  if(THEROCK_RESET_FEATURES)
    set(THEROCK_RESET_FEATURES OFF CACHE BOOL "" FORCE)
    set(THEROCK_RESET_FEATURES OFF PARENT_SCOPE)
  endif()
endfunction()
