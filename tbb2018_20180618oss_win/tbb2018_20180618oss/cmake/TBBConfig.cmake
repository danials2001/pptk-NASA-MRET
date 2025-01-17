# Copyright (c) 2017-2018 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
#
#

# TBB_FOUND should not be set explicitly. It is defined automatically by CMake.
# Handling of TBB_VERSION is in TBBConfigVersion.cmake.

if (NOT TBB_FIND_COMPONENTS)
    set(TBB_FIND_COMPONENTS "tbb;tbbmalloc;tbbmalloc_proxy")
    foreach (_tbb_component ${TBB_FIND_COMPONENTS})
        set(TBB_FIND_REQUIRED_${_tbb_component} 1)
    endforeach()
endif()

# Add components with internal dependencies: tbbmalloc_proxy -> tbbmalloc
list(FIND TBB_FIND_COMPONENTS tbbmalloc_proxy _tbbmalloc_proxy_ix)
if (NOT _tbbmalloc_proxy_ix EQUAL -1)
    list(FIND TBB_FIND_COMPONENTS tbbmalloc _tbbmalloc_ix)
    if (_tbbmalloc_ix EQUAL -1)
        list(APPEND TBB_FIND_COMPONENTS tbbmalloc)
        set(TBB_FIND_REQUIRED_tbbmalloc ${TBB_FIND_REQUIRED_tbbmalloc_proxy})
    endif()
endif()

set(TBB_INTERFACE_VERSION 10005)

get_filename_component(_tbb_root "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_tbb_root "${_tbb_root}" PATH)

set(_tbb_x32_subdir ia32)
set(_tbb_x64_subdir intel64)

if (CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_tbb_arch_subdir ${_tbb_x64_subdir})
else()
    set(_tbb_arch_subdir ${_tbb_x32_subdir})
endif()

if (NOT MSVC)
    message(FATAL_ERROR "This Intel TBB package is intended to be used only in the project with MSVC")
endif()

# Detect the most relevant MSVC subdirectory
set(_tbb_msvc_1700_subdir vc11)
set(_tbb_msvc_1800_subdir vc12)
set(_tbb_msvc_1900_subdir vc14)
set(_tbb_msvc_ver ${MSVC_VERSION})
if (MSVC_VERSION VERSION_LESS 1700)
    message(FATAL_ERROR "This Intel TBB package is intended to be used only in the project with MSVC version 1700 (vc11) or higher")
elseif (MSVC_VERSION VERSION_GREATER 1900)
    set(_tbb_msvc_ver 1900)
endif()
set(_tbb_compiler_subdir ${_tbb_msvc_${_tbb_msvc_ver}_subdir})
unset(_tbb_msvc_1700_subdir)
unset(_tbb_msvc_1800_subdir)
unset(_tbb_msvc_1900_subdir)

if (WINDOWS_STORE)
    set(_tbb_compiler_subdir ${_tbb_compiler_subdir}_ui)
endif()

get_filename_component(_tbb_lib_path "${_tbb_root}/bin/${_tbb_arch_subdir}/${_tbb_compiler_subdir}" ABSOLUTE)

foreach (_tbb_component ${TBB_FIND_COMPONENTS})
    set(_tbb_release_lib "${_tbb_lib_path}/${_tbb_component}.dll")
    set(_tbb_debug_lib "${_tbb_lib_path}/${_tbb_component}_debug.dll")

    if (EXISTS "${_tbb_release_lib}" AND EXISTS "${_tbb_debug_lib}")
        add_library(TBB::${_tbb_component} SHARED IMPORTED)
        set_target_properties(TBB::${_tbb_component} PROPERTIES
                              IMPORTED_CONFIGURATIONS "RELEASE;DEBUG"
                              IMPORTED_LOCATION_RELEASE     "${_tbb_release_lib}"
                              IMPORTED_LOCATION_DEBUG       "${_tbb_debug_lib}"
                              INTERFACE_INCLUDE_DIRECTORIES "${_tbb_root}/include"
                              IMPORTED_IMPLIB_RELEASE       "${_tbb_root}/lib/${_tbb_arch_subdir}/${_tbb_compiler_subdir}/${_tbb_component}.lib"
                              IMPORTED_IMPLIB_DEBUG         "${_tbb_root}/lib/${_tbb_arch_subdir}/${_tbb_compiler_subdir}/${_tbb_component}_debug.lib"
                              INTERFACE_COMPILE_DEFINITIONS "__TBB_NO_IMPLICIT_LINKAGE=1")

        # Add internal dependencies for imported targets: TBB::tbbmalloc_proxy -> TBB::tbbmalloc
        if (_tbb_component STREQUAL tbbmalloc_proxy)
            set_target_properties(TBB::tbbmalloc_proxy PROPERTIES INTERFACE_LINK_LIBRARIES TBB::tbbmalloc)
        endif()

        list(APPEND TBB_IMPORTED_TARGETS TBB::${_tbb_component})
        set(TBB_${_tbb_component}_FOUND 1)
    elseif (TBB_FIND_REQUIRED AND TBB_FIND_REQUIRED_${_tbb_component})
        message(FATAL_ERROR "Missed required Intel TBB component: ${_tbb_component}")
    endif()
endforeach()

unset(_tbb_x32_subdir)
unset(_tbb_x64_subdir)
unset(_tbb_arch_subdir)
unset(_tbb_compiler_subdir)
unset(_tbbmalloc_proxy_ix)
unset(_tbbmalloc_ix)
unset(_tbb_lib_path)
unset(_tbb_release_lib)
unset(_tbb_debug_lib)
