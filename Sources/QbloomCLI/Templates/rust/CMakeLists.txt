cmake_minimum_required(VERSION 3.24)
project({{TARGET}} LANGUAGES CXX)

find_program(CARGO_EXECUTABLE cargo REQUIRED)
find_program(QMAKE_EXECUTABLE qmake6 REQUIRED)
add_custom_target({{EXECUTABLE}} ALL
    COMMAND "${CMAKE_COMMAND}" -E env "QMAKE=${QMAKE_EXECUTABLE}" "CARGO_TARGET_DIR=${CMAKE_BINARY_DIR}" "${CARGO_EXECUTABLE}" build --locked
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    USES_TERMINAL
    VERBATIM
    COMMENT "Build the Rust Qt Quick application with Cargo")
