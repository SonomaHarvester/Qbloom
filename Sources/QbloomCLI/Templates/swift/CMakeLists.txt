cmake_minimum_required(VERSION 3.21)
project({{TARGET}} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Qml QuickControls2)
find_program(SWIFT_EXECUTABLE swift REQUIRED)
qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(SWIFT_CONFIGURATION release)
else()
    set(SWIFT_CONFIGURATION debug)
endif()
set(SWIFT_SCRATCH "${CMAKE_BINARY_DIR}/swift")
if(WIN32)
    execute_process(
        COMMAND "${SWIFT_EXECUTABLE}" build --package-path "${CMAKE_CURRENT_SOURCE_DIR}"
                --scratch-path "${SWIFT_SCRATCH}" --configuration "${SWIFT_CONFIGURATION}"
                --show-bin-path
        OUTPUT_VARIABLE SWIFT_PRODUCTS
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY)
    file(TO_CMAKE_PATH "${SWIFT_PRODUCTS}" SWIFT_PRODUCTS)
    set(SWIFT_LIBRARY "${SWIFT_PRODUCTS}/QbloomSwiftBackend.dll")
    set(SWIFT_IMPORT_LIBRARY "${SWIFT_PRODUCTS}/QbloomSwiftBackend.lib")
else()
    set(SWIFT_LIBRARY "${SWIFT_SCRATCH}/${SWIFT_CONFIGURATION}/libQbloomSwiftBackend${CMAKE_SHARED_LIBRARY_SUFFIX}")
endif()
add_custom_command(
    OUTPUT "${SWIFT_LIBRARY}" ${SWIFT_IMPORT_LIBRARY}
    COMMAND "${SWIFT_EXECUTABLE}" build --package-path "${CMAKE_CURRENT_SOURCE_DIR}"
            --scratch-path "${SWIFT_SCRATCH}" --configuration "${SWIFT_CONFIGURATION}"
            --product QbloomSwiftBackend
    DEPENDS Package.swift Sources/QbloomSwiftBackend/Backend.swift
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    VERBATIM)
add_custom_target(qbloom_swift_library DEPENDS "${SWIFT_LIBRARY}" ${SWIFT_IMPORT_LIBRARY})
add_library(qbloom_swift SHARED IMPORTED GLOBAL)
set_target_properties(qbloom_swift PROPERTIES IMPORTED_LOCATION "${SWIFT_LIBRARY}")
if(WIN32)
    set_target_properties(qbloom_swift PROPERTIES IMPORTED_IMPLIB "${SWIFT_IMPORT_LIBRARY}")
endif()
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # SwiftPM can emit a shared library without an ELF SONAME.
    # Link by name so the loader resolves it through BUILD_RPATH.
    set_target_properties(qbloom_swift PROPERTIES IMPORTED_NO_SONAME TRUE)
endif()

qt_add_executable({{EXECUTABLE}} src/main.cpp src/backend.cpp src/backend.h)
add_dependencies({{EXECUTABLE}} qbloom_swift_library)
if(WIN32)
    add_custom_command(TARGET {{EXECUTABLE}} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "${SWIFT_LIBRARY}" "$<TARGET_FILE_DIR:{{EXECUTABLE}}>"
        VERBATIM)
endif()
target_link_libraries({{EXECUTABLE}} PRIVATE qbloom_swift Qt6::Quick Qt6::Qml Qt6::QuickControls2)
qt_add_qml_module({{EXECUTABLE}} URI {{MODULE_URI}} VERSION 1.0 QML_FILES qml/Main.qml)
set_target_properties({{EXECUTABLE}} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    BUILD_RPATH "${SWIFT_SCRATCH}/${SWIFT_CONFIGURATION}")
