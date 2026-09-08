#include "llama_mobile.h"
#include "llama.cpp-master/common/common.h"
#include <stdexcept>

namespace llama_mobile {

// ---------------------------------------------------------------------------
// Direct loader
//
// We intentionally bypass common_init_from_params(): llama.cpp's convenience
// path (context fitting probes, threadpool attach, etc.) is unstable when
// llama.cpp is embedded as a subproject/library (SIZE_MAX allocations on host
// CPU, see docs/API-design-review.md §3 / docs/API-v2-plan.md). Building the
// model + context directly on the public llama API gives the same result with
// full control, and works on host CPU, Android and iOS backends alike.
// ---------------------------------------------------------------------------

static bool llama_mobile_load_model_and_context(common_params & params,
                                                llama_model ** out_model,
                                                llama_context ** out_ctx) {
    if (!out_model || !out_ctx) {
        return false;
    }

    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers            = params.n_gpu_layers;
    mparams.split_mode              = params.split_mode;
    mparams.main_gpu                = params.main_gpu;
    mparams.tensor_split            = params.tensor_split;
    mparams.load_mode               = params.load_mode;
    mparams.lazy_mode               = params.lazy_mode;
    mparams.progress_callback       = params.load_progress_callback;
    mparams.progress_callback_user_data = params.load_progress_callback_user_data;
    if (!params.devices.empty()) {
        mparams.devices = params.devices.data();
    }
    // Keep tensor handling deterministic and host-stable: no extra-buft weight
    // repacking, no tensor data self-checks, no MTP layers.
    mparams.use_extra_bufts = false;
    mparams.check_tensors   = false;
    mparams.no_host         = false;
    mparams.no_alloc        = false;
    mparams.vocab_only      = false;
    mparams.load_mtp        = false;

    llama_model * model = llama_model_load_from_file(params.model.path.c_str(), mparams);
    if (model == nullptr) {
        LOG_ERROR("unable to load model: %s", params.model.path.c_str());
        return false;
    }

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx     = params.n_ctx     > 0 ? (uint32_t) params.n_ctx     : 0; // 0 = model default
    cparams.n_batch   = params.n_batch   > 0 ? (uint32_t) params.n_batch   : 2048;
    cparams.n_ubatch  = params.n_ubatch  > 0 ? (uint32_t) params.n_ubatch  : cparams.n_batch;
    cparams.n_seq_max = params.n_parallel > 0 ? (uint32_t) params.n_parallel : 1;
    cparams.n_outputs_max     = params.n_outputs_max     > 0 ? (uint32_t) params.n_outputs_max     : 0;
    cparams.n_outputs_max_per_seq = params.n_outputs_max_per_seq > 0 ? (uint32_t) params.n_outputs_max_per_seq : 0;
    cparams.n_threads = params.cpuparams.n_threads;         // -1/0 => engine default
    cparams.n_threads_batch = params.cpuparams_batch.n_threads == -1
        ? params.cpuparams.n_threads : params.cpuparams_batch.n_threads;

    cparams.embeddings        = params.embedding;
    cparams.pooling_type      = params.pooling_type;
    cparams.attention_type    = params.attention_type;
    cparams.flash_attn_type   = params.flash_attn_type;
    cparams.rope_scaling_type = params.rope_scaling_type;
    cparams.rope_freq_base    = params.rope_freq_base;
    cparams.rope_freq_scale   = params.rope_freq_scale;
    cparams.yarn_ext_factor   = params.yarn_ext_factor;
    cparams.yarn_attn_factor  = params.yarn_attn_factor;
    cparams.yarn_beta_fast    = params.yarn_beta_fast;
    cparams.yarn_beta_slow    = params.yarn_beta_slow;
    cparams.yarn_orig_ctx     = params.yarn_orig_ctx;
    cparams.type_k            = params.cache_type_k;
    cparams.type_v            = params.cache_type_v;
    cparams.offload_kqv       = !params.no_kv_offload;
    cparams.op_offload        = !params.no_op_offload;
    cparams.swa_full          = params.swa_full;
    cparams.kv_unified        = params.kv_unified;
    cparams.no_perf           = params.no_perf;
    cparams.cb_eval           = params.cb_eval;
    cparams.cb_eval_user_data = params.cb_eval_user_data;

    llama_context * ctx = llama_new_context_with_model(model, cparams);
    if (ctx == nullptr) {
        LOG_ERROR("unable to create context: %s", params.model.path.c_str());
        llama_free_model(model);
        return false;
    }

    *out_model = model;
    *out_ctx   = ctx;
    return true;
}

// Convenience loader used by llama_mobile_context::loadModel.
bool llama_mobile_load_context_direct(common_params & params,
                                      llama_model ** out_model,
                                      llama_context ** out_ctx) {
    return llama_mobile_load_model_and_context(params, out_model, out_ctx);
}

bool llama_mobile_context::loadModel(common_params &params_) {
    params = params_;
    LOG_INFO("Starting model loading process for: %s", params.model.path.c_str());
    LOG_INFO("Parameters: n_ctx=%d, n_batch=%d, n_gpu_layers=%d, load_mode=%s", 
             params.n_ctx, params.n_batch, params.n_gpu_layers, llama_load_mode_name(params.load_mode));

    // Check if GPU offloading is actually happening
    if (params.n_gpu_layers > 0) {
        LOG_INFO("Requested %d GPU layers offloading", params.n_gpu_layers);
        if (llama_supports_gpu_offload()) {
            LOG_INFO("GPU offload is supported by the current runtime backend.");
        } else {
            LOG_WARNING("GPU offload was requested but the current runtime backend does NOT support it!");
        }
    }

    llama_model * direct_model = nullptr;
    llama_context * direct_ctx = nullptr;
    if (!llama_mobile_load_model_and_context(params, &direct_model, &direct_ctx)) {
        LOG_ERROR("unable to initialize model context: %s. Check if Metal shaders or CUDA kernels are properly configured.", params.model.path.c_str());
        return false;
    }

    model = direct_model;
    ctx   = direct_ctx;
    LOG_INFO("model pointer: %p", model);
    LOG_INFO("context pointer: %p", ctx);

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