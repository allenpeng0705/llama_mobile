#include "llama_mobile.h"
#include "llama.cpp-master/common/common.h"
#include <stdexcept>

namespace llama_mobile {

bool llama_mobile_context::loadModel(common_params &params_) {
    params = params_;
    LOG_INFO("Starting model loading process for: %s", params.model.path.c_str());
    LOG_INFO("Parameters: n_ctx=%d, n_batch=%d, n_gpu_layers=%d, use_mmap=%d, use_mlock=%d", 
             params.n_ctx, params.n_batch, params.n_gpu_layers, params.use_mmap, params.use_mlock);
    
    llama_init = common_init_from_params(params);
    LOG_INFO("common_init_from_params returned: %p", llama_init.get());

    if (llama_init == nullptr) {
        LOG_ERROR("unable to initialize model context: %s. Check if Metal shaders or CUDA kernels are properly configured.", params.model.path.c_str());
        return false;
    }
    
    // Check if GPU offloading is actually happening
    if (params.n_gpu_layers > 0) {
        LOG_INFO("Requested %d GPU layers offloading", params.n_gpu_layers);
        if (llama_supports_gpu_offload()) {
            LOG_INFO("GPU offload is supported by the current runtime backend.");
        } else {
            LOG_WARNING("GPU offload was requested but the current runtime backend does NOT support it!");
        }
    }
    
    model = llama_init->model();
    LOG_INFO("model pointer: %p", model);
    
    ctx = llama_init->context();
    LOG_INFO("context pointer: %p", ctx);
    
    if (model == nullptr) {
        LOG_ERROR("unable to load model: %s", params.model.path.c_str());
        return false;
    }
    
    if (ctx == nullptr) {
        LOG_ERROR("unable to create context: %s", params.model.path.c_str());
        return false;
    }
    
    LOG_INFO("Model and context loaded successfully. Proceeding with template initialization.");
    templates = common_chat_templates_init(model, params.chat_template);
    LOG_INFO("Templates initialized: %p", templates.get());
    
    n_ctx = llama_n_ctx(ctx);
    LOG_INFO("Context size: %d", n_ctx);

    LOG_INFO("Model loading process completed successfully!");
    return true;
}

bool llama_mobile_context::validateModelChatTemplate(bool use_jinja, const char *name) const {
    const char * tmpl = llama_model_chat_template(model, name);
    if (tmpl == nullptr) {
      return false;
    }
    return common_chat_verify_template(tmpl, use_jinja);
}

const std::vector<ggml_type> kv_cache_types = {
    GGML_TYPE_F32,
    GGML_TYPE_F16,
    GGML_TYPE_BF16,
    GGML_TYPE_Q8_0,
    GGML_TYPE_Q4_0,
    GGML_TYPE_Q4_1,
    GGML_TYPE_IQ4_NL,
    GGML_TYPE_Q5_0,
    GGML_TYPE_Q5_1,
};

ggml_type kv_cache_type_from_str(const std::string & s) {
    for (const auto & type : kv_cache_types) {
        if (ggml_type_name(type) == s) {
            return type;
        }
    }
    throw std::runtime_error("Unsupported cache type: " + s);
}

} // namespace llama_mobile 