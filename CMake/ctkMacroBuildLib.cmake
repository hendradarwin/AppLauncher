###########################################################################
#
#  Library:   CTK
#
#  Copyright (c) 2010  Kitware Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.commontk.org/LICENSE
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################

#
# Depends on:
#  <SOURCE>/CMake/ctkMacroParseArguments.cmake
#

#
# See http://github.com/pieper/CTK/blob/master/CMake/ctkMacroBuildLib.cmake
#

#
# If you want to re-use this macro outside of CTK, the line referring to the following items
# may need to be updated to match your project:
#    - ${CTK_SOURCE_DIR}/Libs/CTKExport.h.in
#    - CTK_LIBRARY_PROPERTIES
#    - CTK_INSTALL_BIN_DIR
#    - CTK_INSTALL_LIB_DIR
#

macro(ctkMacroBuildLib)
  set(prefix ${PROJECT_NAME})
  if(prefix STREQUAL "")
    message(SEND_ERROR "prefix should NOT be empty !")
  endif()
  set(options)
  set(oneValueArgs NAME EXPORT_DIRECTIVE LIBRARY_TYPE LABEL)
  set(multiValueArgs SRCS MOC_SRCS UI_FORMS INCLUDE_DIRECTORIES TARGET_LIBRARIES RESOURCES)
  cmake_parse_arguments(${prefix} "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # Sanity checks
  if(NOT DEFINED ${prefix}_NAME)
    message(SEND_ERROR "NAME is mandatory")
  endif()
  if(NOT DEFINED ${prefix}_LIBRARY_TYPE)
    set(${prefix}_LIBRARY_TYPE "SHARED")
  endif()
  if(NOT DEFINED ${prefix}_LABEL)
    set(${prefix}_LABEL ${${prefix}_NAME})
  endif()
  if(NOT DEFINED ${prefix}_EXPORT_DIRECTIVE)
    if(${prefix}_LIBRARY_TYPE STREQUAL "SHARED")
      message(SEND_ERROR "EXPORT_DIRECTIVE is mandatory")
    endif()
  endif()

  # Define library name
  set(lib_name ${${prefix}_NAME})

  # --------------------------------------------------------------------------
  # Include dirs
  set(${PROJECT_NAME}_INCLUDE_DIRS
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    CACHE STRING "${PROJECT_NAME} source and binary include directories" FORCE
    )

  include_directories(
    ${${PROJECT_NAME}_INCLUDE_DIRS}
    ${${prefix}_INCLUDE_DIRECTORIES}
    )

  if(${prefix}_LIBRARY_TYPE STREQUAL "SHARED")
    set(MY_LIBRARY_EXPORT_DIRECTIVE ${${prefix}_EXPORT_DIRECTIVE})
    set(MY_EXPORT_HEADER_PREFIX ${${prefix}_NAME})
    set(MY_LIBNAME ${lib_name})

    configure_file(
      ${CTK_SOURCE_DIR}/Libs/CTKExport.h.in
      ${CMAKE_CURRENT_BINARY_DIR}/${MY_EXPORT_HEADER_PREFIX}Export.h
      )
    set(dynamicHeaders
      "${dynamicHeaders};${CMAKE_CURRENT_BINARY_DIR}/${MY_EXPORT_HEADER_PREFIX}Export.h")
  endif()

  # Make sure variable are cleared
  set(${prefix}_MOC_CXX)
  set(${prefix}_UI_CXX)
  set(${prefix}_QRC_SRCS)

  # Wrap
  QT5_WRAP_CPP(${prefix}_MOC_CXX ${${prefix}_MOC_SRCS})
  QT5_WRAP_UI(${prefix}_UI_CXX ${${prefix}_UI_FORMS})
  if(DEFINED ${prefix}_RESOURCES)
    QT5_ADD_RESOURCES(${prefix}_QRC_SRCS ${${prefix}_RESOURCES})
  endif()

  source_group("Resources" FILES
    ${${prefix}_RESOURCES}
    ${${prefix}_UI_FORMS}
    )

  source_group("Generated" FILES
    ${${prefix}_QRC_SRCS}
    ${${prefix}_MOC_CXX}
    ${${prefix}_UI_CXX}
    )

  add_library(${lib_name} ${${prefix}_LIBRARY_TYPE}
    ${${prefix}_SRCS}
    ${${prefix}_MOC_CXX}
    ${${prefix}_UI_CXX}
    ${${prefix}_QRC_SRCS}
    )

  # Set labels associated with the target.
  set_target_properties(${lib_name} PROPERTIES LABELS ${${prefix}_LABEL})

  # Apply user-defined properties to the library target.
  if(CTK_LIBRARY_PROPERTIES AND ${prefix}_LIBRARY_TYPE STREQUAL "SHARED")
    set_target_properties(${lib_name} PROPERTIES ${CTK_LIBRARY_PROPERTIES})
  endif()

  # Install rules
  if(CTK_BUILD_SHARED_LIBS)
    install(TARGETS ${lib_name}
      RUNTIME DESTINATION ${CTK_INSTALL_BIN_DIR} COMPONENT Runtime
      LIBRARY DESTINATION ${CTK_INSTALL_LIB_DIR} COMPONENT Runtime
      ARCHIVE DESTINATION ${CTK_INSTALL_LIB_DIR} COMPONENT Development)
  endif()

  set(my_libs
    ${${prefix}_TARGET_LIBRARIES}
	Qt5::WinMain
	Qt5::Core
	Qt5::Gui
	Qt5::Widgets	
    )
  target_link_libraries(${lib_name} ${my_libs})

  # Install headers
  #file(GLOB headers "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
  #install(FILES
  #  ${headers}
  #  ${dynamicHeaders}
  #  DESTINATION ${CTK_INSTALL_INCLUDE_DIR} COMPONENT Development
  #  )

endmacro()
