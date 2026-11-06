cmake_minimum_required(VERSION 3.21)
project({{TARGET}} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Qml QuickControls2)
find_program(GO_EXECUTABLE go REQUIRED)
qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

set(GO_LIBRARY_DIR "${CMAKE_BINARY_DIR}")
set(GO_LIBRARY "${GO_LIBRARY_DIR}/libqbloom_go${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(GO_HEADER "${GO_LIBRARY_DIR}/libqbloom_go.h")
if(APPLE)
    set(GO_LINK_FLAGS "-ldflags=-extldflags=-Wl,-install_name,@rpath/libqbloom_go.dylib")
endif()
add_custom_command(
    OUTPUT "${GO_LIBRARY}" "${GO_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${GO_LIBRARY_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E env CGO_ENABLED=1 GOTOOLCHAIN=local GOPROXY=off
            "${GO_EXECUTABLE}" build -buildmode=c-shared ${GO_LINK_FLAGS} -o "${GO_LIBRARY}" ./backend
    DEPENDS go.mod backend/main.go backend/logic/counter.go
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    VERBATIM
)
add_custom_target(qbloom_go_library DEPENDS "${GO_LIBRARY}" "${GO_HEADER}")
add_library(qbloom_go SHARED IMPORTED GLOBAL)
set_target_properties(qbloom_go PROPERTIES IMPORTED_LOCATION "${GO_LIBRARY}")
if(WIN32)
    if(NOT MSVC OR NOT CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "x64")
        message(FATAL_ERROR "The Windows Go backend requires an x64 MSVC Qt kit and a MinGW-compatible cgo compiler")
    endif()
    set(GO_EXPORTS "${CMAKE_CURRENT_SOURCE_DIR}/backend/exports.def")
    set(GO_IMPORT_LIBRARY "${GO_LIBRARY_DIR}/qbloom_go.lib")
    add_custom_command(
        OUTPUT "${GO_IMPORT_LIBRARY}"
        COMMAND "${CMAKE_AR}" /nologo /machine:x64 "/def:${GO_EXPORTS}" "/out:${GO_IMPORT_LIBRARY}"
        DEPENDS "${GO_LIBRARY}" "${GO_EXPORTS}"
        VERBATIM)
    add_custom_target(qbloom_go_import_library DEPENDS "${GO_IMPORT_LIBRARY}")
    add_dependencies(qbloom_go_import_library qbloom_go_library)
    set_target_properties(qbloom_go PROPERTIES IMPORTED_IMPLIB "${GO_IMPORT_LIBRARY}")
endif()

qt_add_executable({{EXECUTABLE}} src/main.cpp src/backend.cpp src/backend.h)
add_dependencies({{EXECUTABLE}} qbloom_go_library)
if(WIN32)
    add_dependencies({{EXECUTABLE}} qbloom_go_import_library)
    add_custom_command(TARGET {{EXECUTABLE}} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "${GO_LIBRARY}" "$<TARGET_FILE_DIR:{{EXECUTABLE}}>"
        VERBATIM)
endif()
target_include_directories({{EXECUTABLE}} PRIVATE "${GO_LIBRARY_DIR}")
target_link_libraries({{EXECUTABLE}} PRIVATE qbloom_go Qt6::Quick Qt6::Qml Qt6::QuickControls2)
qt_add_qml_module({{EXECUTABLE}} URI {{MODULE_URI}} VERSION 1.0 QML_FILES qml/Main.qml)
set_target_properties({{EXECUTABLE}} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    BUILD_RPATH "${GO_LIBRARY_DIR}")
