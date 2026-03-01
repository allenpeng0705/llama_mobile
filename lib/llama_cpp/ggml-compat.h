#ifndef GGML_COMPAT_H
#define GGML_COMPAT_H

#include "ggml.h"
#include "ggml-backend.h"

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// Type compatibility macros
// ============================================================================
#define ggml_backend_t lm_ggml_backend_t
#define ggml_backend_dev_t lm_ggml_backend_dev_t
#define ggml_backend_device lm_ggml_backend_device
#define ggml_tensor lm_ggml_tensor
#define ggml_status lm_ggml_status
#define ggml_cgraph lm_ggml_cgraph
#define ggml_backend_buffer_type_t lm_ggml_backend_buffer_type_t
#define ggml_guid_t lm_ggml_guid_t
#define ggml_guid lm_ggml_guid
#define ggml_backend_i lm_ggml_backend_i
#define ggml_backend lm_ggml_backend
#define ggml_backend_buffer_t lm_ggml_backend_buffer_t
#define ggml_backend_buffer_type_i lm_ggml_backend_buffer_type_i
#define ggml_backend_buffer_type lm_ggml_backend_buffer_type
#define ggml_backend_dev_type lm_ggml_backend_dev_type
#define ggml_backend_dev_props lm_ggml_backend_dev_props
#define ggml_backend_dev_caps lm_ggml_backend_dev_caps
#define ggml_backend_device_i lm_ggml_backend_device_i
#define ggml_backend_reg_t lm_ggml_backend_reg_t
#define ggml_backend_reg_i lm_ggml_backend_reg_i
#define ggml_backend_reg lm_ggml_backend_reg

// For ggml_backend_buffer_i, we need to use the struct directly
// since it's used both as a struct tag and a type
#define ggml_backend_buffer_i struct lm_ggml_backend_buffer_i

// ============================================================================
// Enum type compatibility
// ============================================================================
typedef enum lm_ggml_type ggml_type;
typedef enum lm_ggml_prec ggml_prec;
typedef enum lm_ggml_op ggml_op;
typedef enum lm_ggml_unary_op ggml_unary_op;

// ============================================================================
// Basic function compatibility macros
// ============================================================================
#define ggml_op_name lm_ggml_op_name
#define ggml_get_unary_op lm_ggml_get_unary_op
#define ggml_is_contiguous lm_ggml_is_contiguous
#define ggml_nbytes lm_ggml_nbytes
#define ggml_backend_opencl_reg lm_ggml_backend_opencl_reg
#define ggml_backend_reg_dev_get lm_ggml_backend_reg_dev_get
#define ggml_backend_buffer_init lm_ggml_backend_buffer_init
#define ggml_is_quantized lm_ggml_is_quantized
#define ggml_nelements lm_ggml_nelements
#define ggml_is_contiguous_1 lm_ggml_is_contiguous_1
#define ggml_nrows lm_ggml_nrows
#define ggml_is_transposed lm_ggml_is_transposed
#define ggml_element_size lm_ggml_element_size
#define ggml_type_size lm_ggml_type_size
#define ggml_blck_size lm_ggml_blck_size
#define ggml_type_name lm_ggml_type_name
#define ggml_is_permuted lm_ggml_is_permuted
#define ggml_are_same_shape lm_ggml_are_same_shape
#define ggml_is_empty lm_ggml_is_empty
#define ggml_rope_yarn_corr_dims lm_ggml_rope_yarn_corr_dims
#define ggml_guid_matches lm_ggml_guid_matches
#define ggml_unary_op_name lm_ggml_unary_op_name

// ============================================================================
// Type compatibility macros
// ============================================================================
#define GGML_TYPE_F32 LM_GGML_TYPE_F32
#define GGML_TYPE_F16 LM_GGML_TYPE_F16
#define GGML_TYPE_Q4_0 LM_GGML_TYPE_Q4_0
#define GGML_TYPE_Q4_1 LM_GGML_TYPE_Q4_1
#define GGML_TYPE_Q5_0 LM_GGML_TYPE_Q5_0
#define GGML_TYPE_Q5_1 LM_GGML_TYPE_Q5_1
#define GGML_TYPE_Q8_0 LM_GGML_TYPE_Q8_0
#define GGML_TYPE_Q8_1 LM_GGML_TYPE_Q8_1
#define GGML_TYPE_Q2_K LM_GGML_TYPE_Q2_K
#define GGML_TYPE_Q3_K LM_GGML_TYPE_Q3_K
#define GGML_TYPE_Q4_K LM_GGML_TYPE_Q4_K
#define GGML_TYPE_Q5_K LM_GGML_TYPE_Q5_K
#define GGML_TYPE_Q6_K LM_GGML_TYPE_Q6_K
#define GGML_TYPE_Q8_K LM_GGML_TYPE_Q8_K
#define GGML_TYPE_IQ2_XXS LM_GGML_TYPE_IQ2_XXS
#define GGML_TYPE_IQ2_XS LM_GGML_TYPE_IQ2_XS
#define GGML_TYPE_IQ3_XXS LM_GGML_TYPE_IQ3_XXS
#define GGML_TYPE_IQ1_S LM_GGML_TYPE_IQ1_S
#define GGML_TYPE_IQ4_NL LM_GGML_TYPE_IQ4_NL
#define GGML_TYPE_IQ3_S LM_GGML_TYPE_IQ3_S
#define GGML_TYPE_IQ2_S LM_GGML_TYPE_IQ2_S
#define GGML_TYPE_IQ4_XS LM_GGML_TYPE_IQ4_XS
#define GGML_TYPE_I8 LM_GGML_TYPE_I8
#define GGML_TYPE_I16 LM_GGML_TYPE_I16
#define GGML_TYPE_I32 LM_GGML_TYPE_I32
#define GGML_TYPE_I64 LM_GGML_TYPE_I64
#define GGML_TYPE_F64 LM_GGML_TYPE_F64
#define GGML_TYPE_IQ1_M LM_GGML_TYPE_IQ1_M
#define GGML_TYPE_BF16 LM_GGML_TYPE_BF16
#define GGML_TYPE_TQ1_0 LM_GGML_TYPE_TQ1_0
#define GGML_TYPE_COUNT LM_GGML_TYPE_COUNT

// ============================================================================
// Precision enums
// ============================================================================
#define GGML_PREC_DEFAULT LM_GGML_PREC_DEFAULT
#define GGML_PREC_F32 LM_GGML_PREC_F32

// ============================================================================
// Operation enum compatibility macros
// ============================================================================
#define GGML_OP_NONE LM_GGML_OP_NONE
#define GGML_OP_DUP LM_GGML_OP_DUP
#define GGML_OP_ADD LM_GGML_OP_ADD
#define GGML_OP_ADD_ID LM_GGML_OP_ADD_ID
#define GGML_OP_ADD1 LM_GGML_OP_ADD1
#define GGML_OP_ACC LM_GGML_OP_ACC
#define GGML_OP_SUB LM_GGML_OP_SUB
#define GGML_OP_MUL LM_GGML_OP_MUL
#define GGML_OP_DIV LM_GGML_OP_DIV
#define GGML_OP_SQR LM_GGML_OP_SQR
#define GGML_OP_SQRT LM_GGML_OP_SQRT
#define GGML_OP_LOG LM_GGML_OP_LOG
#define GGML_OP_SIN LM_GGML_OP_SIN
#define GGML_OP_COS LM_GGML_OP_COS
#define GGML_OP_SUM LM_GGML_OP_SUM
#define GGML_OP_SUM_ROWS LM_GGML_OP_SUM_ROWS
#define GGML_OP_CUMSUM LM_GGML_OP_CUMSUM
#define GGML_OP_MEAN LM_GGML_OP_MEAN
#define GGML_OP_ARGMAX LM_GGML_OP_ARGMAX
#define GGML_OP_COUNT_EQUAL LM_GGML_OP_COUNT_EQUAL
#define GGML_OP_REPEAT LM_GGML_OP_REPEAT
#define GGML_OP_REPEAT_BACK LM_GGML_OP_REPEAT_BACK
#define GGML_OP_CONCAT LM_GGML_OP_CONCAT
#define GGML_OP_SILU_BACK LM_GGML_OP_SILU_BACK
#define GGML_OP_NORM LM_GGML_OP_NORM
#define GGML_OP_RMS_NORM LM_GGML_OP_RMS_NORM
#define GGML_OP_RMS_NORM_BACK LM_GGML_OP_RMS_NORM_BACK
#define GGML_OP_GROUP_NORM LM_GGML_OP_GROUP_NORM
#define GGML_OP_L2_NORM LM_GGML_OP_L2_NORM
#define GGML_OP_MUL_MAT LM_GGML_OP_MUL_MAT
#define GGML_OP_MUL_MAT_ID LM_GGML_OP_MUL_MAT_ID
#define GGML_OP_OUT_PROD LM_GGML_OP_OUT_PROD
#define GGML_OP_SCALE LM_GGML_OP_SCALE
#define GGML_OP_SET LM_GGML_OP_SET
#define GGML_OP_CPY LM_GGML_OP_CPY
#define GGML_OP_CONT LM_GGML_OP_CONT
#define GGML_OP_RESHAPE LM_GGML_OP_RESHAPE
#define GGML_OP_VIEW LM_GGML_OP_VIEW
#define GGML_OP_PERMUTE LM_GGML_OP_PERMUTE
#define GGML_OP_TRANSPOSE LM_GGML_OP_TRANSPOSE
#define GGML_OP_GET_ROWS LM_GGML_OP_GET_ROWS
#define GGML_OP_GET_ROWS_BACK LM_GGML_OP_GET_ROWS_BACK
#define GGML_OP_SET_ROWS LM_GGML_OP_SET_ROWS
#define GGML_OP_DIAG LM_GGML_OP_DIAG
#define GGML_OP_DIAG_MASK_INF LM_GGML_OP_DIAG_MASK_INF
#define GGML_OP_DIAG_MASK_ZERO LM_GGML_OP_DIAG_MASK_ZERO
#define GGML_OP_SOFT_MAX LM_GGML_OP_SOFT_MAX
#define GGML_OP_SOFT_MAX_BACK LM_GGML_OP_SOFT_MAX_BACK
#define GGML_OP_ROPE LM_GGML_OP_ROPE
#define GGML_OP_ROPE_BACK LM_GGML_OP_ROPE_BACK
#define GGML_OP_UNARY LM_GGML_OP_UNARY
#define GGML_OP_CLAMP LM_GGML_OP_CLAMP
#define GGML_OP_ARANGE LM_GGML_OP_ARANGE
#define GGML_OP_TIMESTEP_EMBEDDING LM_GGML_OP_TIMESTEP_EMBEDDING
#define GGML_OP_ARGSORT LM_GGML_OP_ARGSORT
#define GGML_OP_LEAKY_RELU LM_GGML_OP_LEAKY_RELU
#define GGML_OP_IM2COL LM_GGML_OP_IM2COL
#define GGML_OP_CONV_TRANSPOSE_1D LM_GGML_OP_CONV_TRANSPOSE_1D
#define GGML_OP_IMAGE_CONVERT LM_GGML_OP_IMAGE_CONVERT
#define GGML_OP_POOL_1D LM_GGML_OP_POOL_1D
#define GGML_OP_POOL_2D LM_GGML_OP_POOL_2D
#define GGML_OP_POOL_2D_BACK LM_GGML_OP_POOL_2D_BACK
#define GGML_OP_UPSCALE LM_GGML_OP_UPSCALE
#define GGML_OP_PAD LM_GGML_OP_PAD
#define GGML_OP_PAD_REFLECT_1D LM_GGML_OP_PAD_REFLECT_1D
#define GGML_OP_WIN_PART LM_GGML_OP_WIN_PART
#define GGML_OP_WIN_UNPART LM_GGML_OP_WIN_UNPART
#define GGML_OP_UNARY_BACK LM_GGML_OP_UNARY_BACK
#define GGML_OP_GET_REL_POS LM_GGML_OP_GET_REL_POS
#define GGML_OP_ADD_REL_POS LM_GGML_OP_ADD_REL_POS
#define GGML_OP_RWKV_WKV6 LM_GGML_OP_RWKV_WKV6
#define GGML_OP_GATED_LINEAR_ATTN LM_GGML_OP_GATED_LINEAR_ATTN
#define GGML_OP_RWKV_WKV7 LM_GGML_OP_RWKV_WKV7
#define GGML_OP_OPT_STEP_ADAMW LM_GGML_OP_OPT_STEP_ADAMW
#define GGML_OP_COUNT LM_GGML_OP_COUNT
#define GGML_OP_FLASH_ATTN_EXT LM_GGML_OP_FLASH_ATTN_EXT

// ============================================================================
// Unary operation compatibility macros
// ============================================================================
#define GGML_UNARY_OP_ABS LM_GGML_UNARY_OP_ABS
#define GGML_UNARY_OP_SGN LM_GGML_UNARY_OP_SGN
#define GGML_UNARY_OP_NEG LM_GGML_UNARY_OP_NEG
#define GGML_UNARY_OP_STEP LM_GGML_UNARY_OP_STEP
#define GGML_UNARY_OP_TANH LM_GGML_UNARY_OP_TANH
#define GGML_UNARY_OP_ELU LM_GGML_UNARY_OP_ELU
#define GGML_UNARY_OP_RELU LM_GGML_UNARY_OP_RELU
#define GGML_UNARY_OP_SIGMOID LM_GGML_UNARY_OP_SIGMOID
#define GGML_UNARY_OP_GELU LM_GGML_UNARY_OP_GELU
#define GGML_UNARY_OP_GELU_QUICK LM_GGML_UNARY_OP_GELU_QUICK
#define GGML_UNARY_OP_SILU LM_GGML_UNARY_OP_SILU
#define GGML_UNARY_OP_HARDSWISH LM_GGML_UNARY_OP_HARDSWISH
#define GGML_UNARY_OP_HARDSIGMOID LM_GGML_UNARY_OP_HARDSIGMOID
#define GGML_UNARY_OP_EXP LM_GGML_UNARY_OP_EXP
#define GGML_UNARY_OP_EXPM1 LM_GGML_UNARY_OP_EXPM1
#define GGML_UNARY_OP_SOFTPLUS LM_GGML_UNARY_OP_SOFTPLUS
#define GGML_UNARY_OP_GELU_ERF LM_GGML_UNARY_OP_GELU_ERF
#define GGML_UNARY_OP_XIELU LM_GGML_UNARY_OP_XIELU
#define GGML_UNARY_OP_FLOOR LM_GGML_UNARY_OP_FLOOR
#define GGML_UNARY_OP_CEIL LM_GGML_UNARY_OP_CEIL

// ============================================================================
// RoPE type compatibility macros
// ============================================================================
#define GGML_ROPE_TYPE_NORMAL LM_GGML_ROPE_TYPE_NORMAL
#define GGML_ROPE_TYPE_NEOX LM_GGML_ROPE_TYPE_NEOX
#define GGML_ROPE_TYPE_MROPE LM_GGML_ROPE_TYPE_MROPE
#define GGML_ROPE_TYPE_VISION LM_GGML_ROPE_TYPE_VISION
#define GGML_ROPE_TYPE_IMROPE LM_GGML_ROPE_TYPE_IMROPE

// ============================================================================
// Backend device type compatibility macros
// ============================================================================
#define GGML_BACKEND_DEVICE_TYPE_CPU LM_GGML_BACKEND_DEVICE_TYPE_CPU
#define GGML_BACKEND_DEVICE_TYPE_GPU LM_GGML_BACKEND_DEVICE_TYPE_GPU
#define GGML_BACKEND_DEVICE_TYPE_IGPU LM_GGML_BACKEND_DEVICE_TYPE_IGPU
#define GGML_BACKEND_DEVICE_TYPE_ACCEL LM_GGML_BACKEND_DEVICE_TYPE_ACCEL

// ============================================================================
// Backend API version compatibility macro
// ============================================================================
#define GGML_BACKEND_API_VERSION LM_GGML_BACKEND_API_VERSION

// ============================================================================
// Backend dynamic loading implementation macro
// ============================================================================
#define GGML_BACKEND_DL_IMPL LM_GGML_BACKEND_DL_IMPL

// ============================================================================
// Status compatibility macros
// ============================================================================
#define GGML_STATUS_SUCCESS LM_GGML_STATUS_SUCCESS

// ============================================================================
// Logging compatibility macros
// ============================================================================
#define GGML_ASSERT LM_GGML_ASSERT
#define GGML_LOG_ERROR LM_GGML_LOG_ERROR
#define GGML_LOG_INFO LM_GGML_LOG_INFO
#define GGML_LOG_WARN LM_GGML_LOG_WARN
#define GGML_LOG_DEBUG LM_GGML_LOG_DEBUG
#define GGML_UNUSED LM_GGML_UNUSED
#define GGML_ABORT LM_GGML_ABORT

// ============================================================================
// Tensor locals macros (used by Vulkan backend)
// ============================================================================
#define GGML_TENSOR_LOCALS LM_GGML_TENSOR_LOCALS
#define GGML_TENSOR_LOCALS_1 LM_GGML_TENSOR_LOCALS_1
#define GGML_TENSOR_LOCALS_2 LM_GGML_TENSOR_LOCALS_2
#define GGML_TENSOR_LOCALS_3 LM_GGML_TENSOR_LOCALS_3

// ============================================================================
// OpenCL backend compatibility macros
// ============================================================================
#define ggml_backend_opencl_init lm_ggml_backend_opencl_init
#define ggml_backend_is_opencl lm_ggml_backend_is_opencl
#define ggml_backend_opencl_get_device_count lm_ggml_backend_opencl_get_device_count
#define ggml_backend_opencl_get_device_description lm_ggml_backend_opencl_get_device_description
#define ggml_backend_opencl_get_device_memory lm_ggml_backend_opencl_get_device_memory
#define ggml_backend_opencl_buffer_type lm_ggml_backend_opencl_buffer_type
#define ggml_backend_opencl_host_buffer_type lm_ggml_backend_opencl_host_buffer_type

// ============================================================================
// Vulkan backend compatibility macros
// ============================================================================
#define ggml_backend_vk_reg lm_ggml_backend_vk_reg
#define ggml_backend_vk_init lm_ggml_backend_vk_init
#define ggml_backend_is_vk lm_ggml_backend_is_vk
#define ggml_backend_vk_get_device_count lm_ggml_backend_vk_get_device_count
#define ggml_backend_vk_get_device_description lm_ggml_backend_vk_get_device_description
#define ggml_backend_vk_get_device_memory lm_ggml_backend_vk_get_device_memory
#define ggml_backend_vk_buffer_type lm_ggml_backend_vk_buffer_type
#define ggml_backend_vk_host_buffer_type lm_ggml_backend_vk_host_buffer_type

// ============================================================================
// Additional type compatibility for GPU backends
// ============================================================================
#define ggml_fp16_t lm_ggml_fp16_t
#define ggml_backend_buffer lm_ggml_backend_buffer

// ============================================================================
// Backend helper functions
// ============================================================================
#define ggml_backend_cpu_buffer_from_ptr lm_ggml_backend_cpu_buffer_from_ptr
#define ggml_backend_cpu_buffer_type lm_ggml_backend_cpu_buffer_type
#define ggml_backend_buft_alloc_buffer lm_ggml_backend_buft_alloc_buffer
#define ggml_backend_buffer_is_host lm_ggml_backend_buffer_is_host

#ifdef __cplusplus
}
#endif

#endif // GGML_COMPAT_H
