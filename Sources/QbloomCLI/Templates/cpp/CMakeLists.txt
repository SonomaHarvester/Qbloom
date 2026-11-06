cmake_minimum_required(VERSION 3.21)
project({{TARGET}} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick Qml QuickControls2)
qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)
qt_add_executable({{EXECUTABLE}} src/main.cpp src/backend.cpp src/backend.h)
if(WIN32 AND Qt6_VERSION VERSION_EQUAL "6.11.2")
    get_target_property(QBLOOM_QT_CORE_TYPE Qt6::Core TYPE)
    if(QBLOOM_QT_CORE_TYPE STREQUAL "SHARED_LIBRARY" AND
       (NOT CMAKE_CURRENT_SOURCE_DIR MATCHES "^[ -~]+$" OR
        NOT CMAKE_CURRENT_BINARY_DIR MATCHES "^[ -~]+$"))
        # This scanner reads UTF-8 response files using the Windows local code page.
        set(QBLOOM_QML_SCAN_OPTION NO_IMPORT_SCAN)
    endif()
endif()
qt_add_qml_module({{EXECUTABLE}} URI {{MODULE_URI}} VERSION 1.0
    ${QBLOOM_QML_SCAN_OPTION} QML_FILES qml/Main.qml)
target_link_libraries({{EXECUTABLE}} PRIVATE Qt6::Quick Qt6::Qml Qt6::QuickControls2)
set_target_properties({{EXECUTABLE}} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
