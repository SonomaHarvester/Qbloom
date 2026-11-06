cmake_minimum_required(VERSION 3.21)
project({{TARGET}} LANGUAGES NONE)
find_package(Python3 3.10...<3.15 REQUIRED COMPONENTS Interpreter)
add_custom_target(qbloom_python_run
    COMMAND "${Python3_EXECUTABLE}" -m qbloom_app
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Launch the PySide6 Qt Quick application")
