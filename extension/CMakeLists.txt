include(FetchContent)

function(disable_msvc_warnings target_name)
	if(MSVC AND TARGET ${target_name})
		target_compile_options(${target_name} PRIVATE /wd4244 /wd4267 /wd4305 /wd4996)
	endif()
endfunction()

FetchContent_Declare(
	libopenmpt_source
	URL https://lib.openmpt.org/files/libopenmpt/src/libopenmpt-0.8.4+release.msvc.zip
)

FetchContent_GetProperties(libopenmpt_source)
if(NOT libopenmpt_source_POPULATED)
	FetchContent_Populate(libopenmpt_source)
endif()

set(OPENMPT_ROOT "${libopenmpt_source_SOURCE_DIR}")

file(GLOB LIBOPENMPT_COMMON_SOURCES CONFIGURE_DEPENDS "${OPENMPT_ROOT}/common/*.cpp")
file(GLOB LIBOPENMPT_SOUNDDSP_SOURCES CONFIGURE_DEPENDS "${OPENMPT_ROOT}/sounddsp/*.cpp")
file(GLOB LIBOPENMPT_SOUNDLIB_SOURCES CONFIGURE_DEPENDS "${OPENMPT_ROOT}/soundlib/*.cpp")
file(GLOB LIBOPENMPT_PLUGIN_SOURCES CONFIGURE_DEPENDS "${OPENMPT_ROOT}/soundlib/plugins/*.cpp")
file(GLOB LIBOPENMPT_PLUGIN_DMO_SOURCES CONFIGURE_DEPENDS "${OPENMPT_ROOT}/soundlib/plugins/dmo/*.cpp")
file(GLOB LIBOPENMPT_LIBRARY_SOURCES CONFIGURE_DEPENDS "${OPENMPT_ROOT}/libopenmpt/*.cpp")

add_library(libopenmpt STATIC
	${LIBOPENMPT_COMMON_SOURCES}
	${LIBOPENMPT_SOUNDDSP_SOURCES}
	${LIBOPENMPT_SOUNDLIB_SOURCES}
	${LIBOPENMPT_PLUGIN_SOURCES}
	${LIBOPENMPT_PLUGIN_DMO_SOURCES}
	${LIBOPENMPT_LIBRARY_SOURCES}
)

target_compile_features(libopenmpt PUBLIC cxx_std_17)
target_compile_definitions(libopenmpt PRIVATE LIBOPENMPT_BUILD)
target_include_directories(libopenmpt PUBLIC
	"${OPENMPT_ROOT}"
	"${OPENMPT_ROOT}/common"
	"${OPENMPT_ROOT}/src"
)

if(MSVC)
	target_compile_options(libopenmpt PRIVATE /Zc:preprocessor)
	target_compile_definitions(libopenmpt PRIVATE UNICODE _UNICODE)
endif()

set_target_properties(libopenmpt PROPERTIES POSITION_INDEPENDENT_CODE ON)
disable_msvc_warnings(libopenmpt)

add_library(extension SHARED extension.cpp)

set_target_properties(extension PROPERTIES
	OUTPUT_NAME "openmpt"
	SUFFIX ".hdll"
)

if(WIN32)
	target_include_directories(extension PRIVATE "$ENV{HASHLINK}/include")
	target_link_libraries(extension PRIVATE "$ENV{HASHLINK}/libhl.lib")
endif()

target_link_libraries(extension PRIVATE libopenmpt)
disable_msvc_warnings(extension)