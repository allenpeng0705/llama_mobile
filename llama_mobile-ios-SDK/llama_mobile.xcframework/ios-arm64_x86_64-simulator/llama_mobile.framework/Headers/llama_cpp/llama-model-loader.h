#pragma once

#include "llama.h"

#include "llama-impl.h"
#include "llama-arch.h"
#include "llama-mmap.h"

#include "ggml-cpp.h"

#include <cstddef>
#include <map>
#include <stdexcept>
#include <unordered_map>

using llama_buf_map = std::unordered_map<uint32_t, lm_ggml_backend_buffer_t>;

enum llama_fver {
    LM_GGUF_FILE_VERSION_V1 = 1,
    LM_GGUF_FILE_VERSION_V2 = 2,
    LM_GGUF_FILE_VERSION_V3 = 3,
};

const char * llama_file_version_name(llama_fver version);

struct llama_model_loader {
    // Holds information on a model weight
    struct llama_tensor_weight {
        uint16_t  idx; // source file index
        size_t   offs; // tensor data offset in the original file

        lm_ggml_tensor * tensor;

        llama_tensor_weight(const llama_file * file, uint16_t idx, const struct lm_gguf_context * lm_gguf_ctx, lm_ggml_tensor * tensor) : idx(idx), tensor(tensor) {
            const char * tensor_name = lm_ggml_get_name(tensor);
            
            // Detailed logging for tensor lookup and index validation
            LLAMA_LOG_INFO("llama_tensor_weight: Processing tensor '%s'", tensor_name);
            LLAMA_LOG_INFO("llama_tensor_weight: Input params - file_idx=%u, lm_gguf_ctx=%p, tensor=%p", idx, lm_gguf_ctx, tensor);
            
            if (!lm_gguf_ctx) {
                LLAMA_LOG_ERROR("llama_tensor_weight: ERROR - lm_gguf_ctx is NULL");
                throw std::runtime_error(format("lm_gguf_ctx is NULL for tensor '%s'", tensor_name));
            }
            
            if (!tensor) {
                LLAMA_LOG_ERROR("llama_tensor_weight: ERROR - tensor is NULL");
                throw std::runtime_error(format("tensor is NULL for tensor '%s'", tensor_name));
            }
            
            if (!tensor_name || strlen(tensor_name) == 0) {
                LLAMA_LOG_ERROR("llama_tensor_weight: ERROR - tensor name is NULL or empty");
                throw std::runtime_error("tensor name is NULL or empty");
            }
            
            LLAMA_LOG_INFO("llama_tensor_weight: Looking up tensor '%s' in GGUF context", tensor_name);
            const int tensor_idx = lm_gguf_find_tensor(lm_gguf_ctx, tensor_name);
            
            LLAMA_LOG_INFO("llama_tensor_weight: lm_gguf_find_tensor returned index %d for tensor '%s'", tensor_idx, tensor_name);
            
            if (tensor_idx < 0) {
                LLAMA_LOG_ERROR("llama_tensor_weight: ERROR - tensor '%s' not found in the model", tensor_name);
                throw std::runtime_error(format("tensor '%s' not found in the model", tensor_name));
            }
            
            // Validate the tensor index is valid
            const int n_tensors = lm_gguf_get_n_tensors(lm_gguf_ctx);
            LLAMA_LOG_INFO("llama_tensor_weight: GGUF context has %d total tensors, requested index %d", n_tensors, tensor_idx);
            
            if (tensor_idx >= n_tensors) {
                LLAMA_LOG_ERROR("llama_tensor_weight: ERROR - tensor index %d out of bounds (max %d) for tensor '%s'", tensor_idx, n_tensors - 1, tensor_name);
                throw std::runtime_error(format("tensor index %d out of bounds for tensor '%s'", tensor_idx, tensor_name));
            }
            
            const size_t data_offset = lm_gguf_get_data_offset(lm_gguf_ctx);
            LLAMA_LOG_INFO("llama_tensor_weight: Data offset from GGUF context: %zu", data_offset);
            
            const size_t tensor_offset = lm_gguf_get_tensor_offset(lm_gguf_ctx, tensor_idx);
            LLAMA_LOG_INFO("llama_tensor_weight: Tensor offset for index %d: %zu", tensor_idx, tensor_offset);
            
            if (tensor_offset == (size_t)-1) {
                LLAMA_LOG_ERROR("llama_tensor_weight: ERROR - Invalid tensor offset (0x%zx) for tensor '%s' at index %d", tensor_offset, tensor_name, tensor_idx);
                throw std::runtime_error(format("invalid tensor offset for tensor '%s'", tensor_name));
            }
            
            offs = data_offset + tensor_offset;
            LLAMA_LOG_INFO("llama_tensor_weight: Calculated total offset for tensor '%s': %zu (data_offset=%zu + tensor_offset=%zu)", tensor_name, offs, data_offset, tensor_offset);
            
            LLAMA_LOG_INFO("llama_tensor_weight: tensor '%s' data offset: %zu + %zu = %zu", tensor_name, data_offset, tensor_offset, offs);
            
            const size_t tensor_size = lm_ggml_nbytes(tensor);
            const size_t end_offs = offs + tensor_size;
            
            LLAMA_LOG_INFO("llama_tensor_weight: tensor '%s' size: %zu bytes, ends at %zu (file size: %zu)", 
                          tensor_name, tensor_size, end_offs, file->size());
            
            if (end_offs < offs || end_offs > file->size()) {
                LLAMA_LOG_ERROR("llama_tensor_weight: tensor '%s' data is not within the file bounds", tensor_name);
                throw std::runtime_error(format("tensor '%s' data is not within the file bounds, model is corrupted or incomplete", tensor_name));
            }
        }
    };

    // custom comparator to sort weights more nicely by layer
    struct weight_name_comparer {
        bool operator()(const std::string & a, const std::string & b) const {
            int a_layer = -1;
            int b_layer = -1;
            sscanf(a.c_str(), "blk.%d.", &a_layer);
            sscanf(b.c_str(), "blk.%d.", &b_layer);
            if (a_layer != b_layer) {
                return a_layer < b_layer;
            }
            return a < b;
        }
    };

    static const int TENSOR_NOT_REQUIRED = 1 << 0;
    static const int TENSOR_DUPLICATED   = 1 << 1;
    static const int TENSOR_SKIP         = 1 << 2;

    int n_kv      = 0;
    int n_tensors = 0;
    int n_created = 0;

    uint64_t n_elements = 0;
    size_t   n_bytes    = 0;

    bool use_mmap = false;
    bool check_tensors;
    bool no_alloc;

    llama_files files;
    llama_ftype ftype;
    llama_fver  fver;

    llama_mmaps mappings;

    std::map<std::string, llama_tensor_weight, weight_name_comparer> weights_map;
    std::unordered_map<std::string, llama_model_kv_override> kv_overrides;
    const llama_model_tensor_buft_override * tensor_buft_overrides;

    lm_gguf_context_ptr meta;
    std::vector<lm_ggml_context_ptr> contexts;

    std::string arch_name;
    LLM_KV      llm_kv    = LLM_KV(LLM_ARCH_UNKNOWN);

    size_t size_done = 0;
    size_t size_data = 0;
    std::vector<std::pair<size_t, size_t>> mmaps_used;

    llama_model_loader(
        const std::string & fname,
        std::vector<std::string> & splits, // optional, only need if the split does not follow naming scheme
        bool use_mmap,
        bool check_tensors,
        bool no_alloc,
        const llama_model_kv_override * param_overrides_p,
        const llama_model_tensor_buft_override * param_tensor_buft_overrides_p);

    template<typename T>
    typename std::enable_if<std::is_integral<T>::value, bool>::type
    get_arr_n(const std::string & key, T & result, bool required = true);

    template<typename T>
    typename std::enable_if<std::is_integral<T>::value, bool>::type
    get_arr_n(enum llm_kv kid, T & result, bool required = true);

    template<typename T>
    bool get_arr(const std::string & key, std::vector<T> & result, bool required = true);

    template<typename T, size_t N_MAX>
    bool get_arr(const std::string & key, std::array<T, N_MAX> & result, bool required = true);

    template<typename T>
    bool get_arr(enum llm_kv kid, T & result, bool required = true);

    template<typename T>
    bool get_key(const std::string & key, T & result, bool required = true);

    template<typename T>
    bool get_key(enum llm_kv kid, T & result, bool required = true);

    template<typename T, size_t N_MAX>
    bool get_key_or_arr(const std::string & key, std::array<T, N_MAX> & result, uint32_t n, bool required = true);

    template<typename T>
    bool get_key_or_arr(enum llm_kv kid, T & result, uint32_t n, bool required = true);

    bool get_key_or_arr(enum llm_kv kid, uint32_t & result, bool required = true);

    std::string get_arch_name() const;

    enum llm_arch get_arch() const;

    const llama_tensor_weight * get_weight(const char * name) const;

    const llama_tensor_weight & require_weight(const char * name) const;

    struct lm_ggml_tensor * get_tensor_meta(const char * name) const;

    struct lm_ggml_tensor * require_tensor_meta(const std::string & name) const;

    const struct lm_ggml_tensor * check_tensor_dims(const std::string & name, const std::vector<int64_t> & ne, bool required) const;

    struct lm_ggml_tensor * create_tensor(struct lm_ggml_context * ctx, const std::string & name, const std::initializer_list<int64_t> & ne, int flags = 0);

    struct lm_ggml_tensor * create_tensor_as_view(struct lm_ggml_context * ctx, struct lm_ggml_tensor * base, const std::string & name, const std::initializer_list<int64_t> & ne, size_t offset, bool required = true);

    void done_getting_tensors() const;

    void init_mappings(bool prefetch = true, llama_mlocks * mlock_mmaps = nullptr);

    void get_mapping_range(size_t * first, size_t * last, void ** addr, int idx, lm_ggml_context * ctx) const;

    // for backwards compatibility, does not support ggml-backend
    void load_data_for(struct lm_ggml_tensor * cur) const;

    // Returns false if cancelled by progress_callback
    bool load_all_data(
            struct lm_ggml_context * ctx,
            llama_buf_map & bufs,
            llama_mlocks * lmlocks,
            llama_progress_callback progress_callback,
            void * progress_callback_user_data);

    std::string ftype_name() const;

    void print_info() const;
};
