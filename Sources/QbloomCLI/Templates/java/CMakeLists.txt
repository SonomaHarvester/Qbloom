cmake_minimum_required(VERSION 3.21)
project({{TARGET}} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Qml QuickControls2)
find_package(JNI REQUIRED)
qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

add_library(qbloom_java_qt SHARED src/native/bridge.cpp src/native/backend.cpp src/native/backend.h)
target_include_directories(qbloom_java_qt PRIVATE ${JNI_INCLUDE_DIRS})
target_link_libraries(qbloom_java_qt PRIVATE Qt6::Quick Qt6::Qml Qt6::QuickControls2)
string(REPLACE "." "/" QBLOOM_MODULE_PATH "{{MODULE_URI}}")
qt_add_qml_module(qbloom_java_qt URI {{MODULE_URI}} VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${QBLOOM_MODULE_PATH}"
    NO_PLUGIN
    QML_FILES qml/Main.qml)
set_target_properties(qbloom_java_qt PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

find_program(GRADLE_EXECUTABLE NAMES gradle gradle.bat REQUIRED)
add_custom_target(java_classes
    COMMAND "${GRADLE_EXECUTABLE}" --offline --no-daemon classes
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    VERBATIM)
add_dependencies(qbloom_java_qt java_classes)
