cmake_minimum_required(VERSION 3.18.1)

project(opencl_stub C)

# Build OpenCL stub library as a static library
add_library(OpenCL STATIC opencl_stub.c)

# Set properties
target_include_directories(OpenCL PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
