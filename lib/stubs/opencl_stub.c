/*
 * OpenCL Stub Library for Android Build
 *
 * This is a minimal stub implementation of OpenCL functions for build-time linking.
 * The actual OpenCL implementation will be loaded at runtime from the device.
 *
 * These stubs satisfy the linker but will not be called at runtime
 * because llama.cpp uses dlopen() to load the real OpenCL library.
 */

#include <stdlib.h>
#include <stdint.h>

// OpenCL types (minimal definitions)
typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;
typedef void* cl_platform_id;
typedef void* cl_device_id;
typedef void* cl_context;
typedef void* cl_command_queue;
typedef void* cl_mem;
typedef void* cl_program;
typedef void* cl_kernel;
typedef void* cl_event;
typedef void* cl_sampler;

// Platform API
cl_int clGetPlatformIDs(cl_uint num_entries, cl_platform_id* platforms, cl_uint* num_platforms) {
    return -1; // CL_INVALID_VALUE
}

cl_int clGetPlatformInfo(cl_platform_id platform, cl_uint param_name, size_t param_value_size,
                         void* param_value, size_t* param_value_size_ret) {
    return -1;
}

// Device API
cl_int clGetDeviceIDs(cl_platform_id platform, cl_uint device_type, cl_uint num_entries,
                      cl_device_id* devices, cl_uint* num_devices) {
    return -1;
}

cl_int clGetDeviceInfo(cl_device_id device, cl_uint param_name, size_t param_value_size,
                       void* param_value, size_t* param_value_size_ret) {
    return -1;
}

// Context API
cl_context clCreateContext(const void* properties, cl_uint num_devices, const cl_device_id* devices,
                           void* pfn_notify, void* user_data, cl_int* errcode_ret) {
    if (errcode_ret) *errcode_ret = -1;
    return NULL;
}

cl_int clReleaseContext(cl_context context) {
    return -1;
}

// Command Queue API
cl_command_queue clCreateCommandQueue(cl_context context, cl_device_id device,
                                      cl_uint properties, cl_int* errcode_ret) {
    if (errcode_ret) *errcode_ret = -1;
    return NULL;
}

cl_int clReleaseCommandQueue(cl_command_queue command_queue) {
    return -1;
}

// Memory API
cl_mem clCreateBuffer(cl_context context, cl_uint flags, size_t size, void* host_ptr, cl_int* errcode_ret) {
    if (errcode_ret) *errcode_ret = -1;
    return NULL;
}

cl_int clReleaseMemObject(cl_mem memobj) {
    return -1;
}

cl_int clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer, cl_uint blocking_write,
                            size_t offset, size_t size, const void* ptr, cl_uint num_events_in_wait_list,
                            const cl_event* event_wait_list, cl_event* event) {
    return -1;
}

cl_int clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer, cl_uint blocking_read,
                           size_t offset, size_t size, void* ptr, cl_uint num_events_in_wait_list,
                           const cl_event* event_wait_list, cl_event* event) {
    return -1;
}

// Program API
cl_program clCreateProgramWithSource(cl_context context, cl_uint count, const char** strings,
                                     const size_t* lengths, cl_int* errcode_ret) {
    if (errcode_ret) *errcode_ret = -1;
    return NULL;
}

cl_int clBuildProgram(cl_program program, cl_uint num_devices, const cl_device_id* device_list,
                      const char* options, void* pfn_notify, void* user_data) {
    return -1;
}

cl_int clGetProgramBuildInfo(cl_program program, cl_device_id device, cl_uint param_name,
                             size_t param_value_size, void* param_value, size_t* param_value_size_ret) {
    return -1;
}

cl_int clReleaseProgram(cl_program program) {
    return -1;
}

// Kernel API
cl_kernel clCreateKernel(cl_program program, const char* kernel_name, cl_int* errcode_ret) {
    if (errcode_ret) *errcode_ret = -1;
    return NULL;
}

cl_int clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size, const void* arg_value) {
    return -1;
}

cl_int clReleaseKernel(cl_kernel kernel) {
    return -1;
}

// Execution API
cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel, cl_uint work_dim,
                              const size_t* global_work_offset, const size_t* global_work_size,
                              const size_t* local_work_size, cl_uint num_events_in_wait_list,
                              const cl_event* event_wait_list, cl_event* event) {
    return -1;
}

// Synchronization API
cl_int clFinish(cl_command_queue command_queue) {
    return -1;
}

cl_int clFlush(cl_command_queue command_queue) {
    return -1;
}

// Event API
cl_int clReleaseEvent(cl_event event) {
    return -1;
}

cl_int clWaitForEvents(cl_uint num_events, const cl_event* event_list) {
    return -1;
}
