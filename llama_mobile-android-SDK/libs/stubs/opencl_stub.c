// OpenCL stub implementation for Android build
// This provides minimal implementations of OpenCL functions to satisfy the linker
// The actual OpenCL library will be loaded at runtime by llama.cpp using dlopen()

#include <stdint.h>

// OpenCL error codes
#define CL_SUCCESS 0
#define CL_DEVICE_NOT_FOUND -1

// OpenCL types (minimal definitions)
typedef uintptr_t cl_platform_id;
typedef uintptr_t cl_device_id;
typedef uintptr_t cl_context;
typedef uintptr_t cl_command_queue;
typedef uintptr_t cl_mem;
typedef uintptr_t cl_program;
typedef uintptr_t cl_kernel;
typedef uintptr_t cl_event;
typedef uintptr_t cl_sampler;
typedef uintptr_t cl_int;
typedef uintptr_t cl_uint;
typedef uintptr_t cl_bool;
typedef uintptr_t cl_bitfield;
typedef uintptr_t cl_size_t;
typedef uintptr_t cl_device_type;
typedef uintptr_t cl_context_properties;
typedef uintptr_t cl_command_queue_properties;
typedef uintptr_t cl_mem_flags;
typedef uintptr_t cl_program_properties;
typedef uintptr_t cl_kernel_arg_flags;

// Function prototypes for OpenCL functions referenced by llama.cpp
cl_int clGetPlatformIDs(cl_uint num_entries, cl_platform_id *platforms, cl_uint *num_platforms);
cl_int clGetPlatformInfo(cl_platform_id platform, uintptr_t param_name, size_t param_value_size, void *param_value, size_t *param_value_size_ret);
cl_int clGetDeviceIDs(cl_platform_id platform, cl_device_type device_type, cl_uint num_entries, cl_device_id *devices, cl_uint *num_devices);
cl_int clGetDeviceInfo(cl_device_id device, uintptr_t param_name, size_t param_value_size, void *param_value, size_t *param_value_size_ret);
cl_context clCreateContext(const cl_context_properties *properties, cl_uint num_devices, const cl_device_id *devices, void (*pfn_notify)(const char *errinfo, const void *private_info, size_t cb, void *user_data), void *user_data, cl_int *errcode_ret);
cl_command_queue clCreateCommandQueueWithProperties(cl_context context, cl_device_id device, const cl_command_queue_properties *properties, cl_int *errcode_ret);
cl_command_queue clCreateCommandQueue(cl_context context, cl_device_id device, cl_command_queue_properties properties, cl_int *errcode_ret);
cl_mem clCreateBuffer(cl_context context, cl_mem_flags flags, size_t size, void *host_ptr, cl_int *errcode_ret);
cl_program clCreateProgramWithSource(cl_context context, cl_uint count, const char **strings, const size_t *lengths, cl_int *errcode_ret);
cl_int clBuildProgram(cl_program program, cl_uint num_devices, const cl_device_id *device_list, const char *options, void (*pfn_notify)(cl_program program, void *user_data), void *user_data);
cl_int clGetProgramBuildInfo(cl_program program, cl_device_id device, uintptr_t param_name, size_t param_value_size, void *param_value, size_t *param_value_size_ret);
cl_kernel clCreateKernel(cl_program program, const char *kernel_name, cl_int *errcode_ret);
cl_int clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size, const void *arg_value);
cl_int clGetKernelSubGroupInfo(cl_kernel kernel, cl_device_id device, uintptr_t param_name, size_t input_value_size, const void *input_value, size_t param_value_size, void *param_value, size_t *param_value_size_ret);
cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel, cl_uint work_dim, const size_t *global_work_offset, const size_t *global_work_size, const size_t *local_work_size, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event);
cl_int clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer, cl_bool blocking_read, size_t offset, size_t size, void *ptr, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event);
cl_int clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer, cl_bool blocking_write, size_t offset, size_t size, const void *ptr, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event);
cl_int clEnqueueFillBuffer(cl_command_queue command_queue, cl_mem buffer, const void *pattern, size_t pattern_size, size_t offset, size_t size, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event);
cl_int clFlush(cl_command_queue command_queue);
cl_int clFinish(cl_command_queue command_queue);
cl_int clReleaseMemObject(cl_mem memobj);
cl_int clReleaseKernel(cl_kernel kernel);
cl_int clReleaseProgram(cl_program program);
cl_int clReleaseCommandQueue(cl_command_queue command_queue);
cl_int clReleaseContext(cl_context context);
cl_int clReleaseDevice(cl_device_id device);
cl_int clReleasePlatform(cl_platform_id platform);

// Minimal implementations that return error codes
cl_int clGetPlatformIDs(cl_uint num_entries, cl_platform_id *platforms, cl_uint *num_platforms) {
    if (num_platforms) *num_platforms = 0;
    return CL_DEVICE_NOT_FOUND;
}

cl_int clGetPlatformInfo(cl_platform_id platform, uintptr_t param_name, size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clGetDeviceIDs(cl_platform_id platform, cl_device_type device_type, cl_uint num_entries, cl_device_id *devices, cl_uint *num_devices) {
    if (num_devices) *num_devices = 0;
    return CL_DEVICE_NOT_FOUND;
}

cl_int clGetDeviceInfo(cl_device_id device, uintptr_t param_name, size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    return CL_DEVICE_NOT_FOUND;
}

cl_context clCreateContext(const cl_context_properties *properties, cl_uint num_devices, const cl_device_id *devices, void (*pfn_notify)(const char *errinfo, const void *private_info, size_t cb, void *user_data), void *user_data, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return 0;
}

cl_command_queue clCreateCommandQueueWithProperties(cl_context context, cl_device_id device, const cl_command_queue_properties *properties, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return 0;
}

cl_mem clCreateBuffer(cl_context context, cl_mem_flags flags, size_t size, void *host_ptr, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return 0;
}

cl_program clCreateProgramWithSource(cl_context context, cl_uint count, const char **strings, const size_t *lengths, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return 0;
}

cl_int clBuildProgram(cl_program program, cl_uint num_devices, const cl_device_id *device_list, const char *options, void (*pfn_notify)(cl_program program, void *user_data), void *user_data) {
    return CL_DEVICE_NOT_FOUND;
}

cl_kernel clCreateKernel(cl_program program, const char *kernel_name, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return 0;
}

cl_int clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size, const void *arg_value) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel, cl_uint work_dim, const size_t *global_work_offset, const size_t *global_work_size, const size_t *local_work_size, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer, cl_bool blocking_read, size_t offset, size_t size, void *ptr, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer, cl_bool blocking_write, size_t offset, size_t size, const void *ptr, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clFlush(cl_command_queue command_queue) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clFinish(cl_command_queue command_queue) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleaseMemObject(cl_mem memobj) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleaseKernel(cl_kernel kernel) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleaseProgram(cl_program program) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleaseCommandQueue(cl_command_queue command_queue) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleaseContext(cl_context context) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleaseDevice(cl_device_id device) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clReleasePlatform(cl_platform_id platform) {
    return CL_DEVICE_NOT_FOUND;
}

cl_command_queue clCreateCommandQueue(cl_context context, cl_device_id device, cl_command_queue_properties properties, cl_int *errcode_ret) {
    if (errcode_ret) *errcode_ret = CL_DEVICE_NOT_FOUND;
    return 0;
}

cl_int clGetProgramBuildInfo(cl_program program, cl_device_id device, uintptr_t param_name, size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clGetKernelSubGroupInfo(cl_kernel kernel, cl_device_id device, uintptr_t param_name, size_t input_value_size, const void *input_value, size_t param_value_size, void *param_value, size_t *param_value_size_ret) {
    return CL_DEVICE_NOT_FOUND;
}

cl_int clEnqueueFillBuffer(cl_command_queue command_queue, cl_mem buffer, const void *pattern, size_t pattern_size, size_t offset, size_t size, cl_uint num_events_in_wait_list, const cl_event *event_wait_list, cl_event *event) {
    return CL_DEVICE_NOT_FOUND;
}
