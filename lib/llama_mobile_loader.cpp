#include "llama_mobile.h"
#include "llama_cpp/common.h"
#include <stdexcept>

namespace llama_mobile {

bool llama_mobile_context::loadModel(common_params &params_)
{
    params = params_;
    llama_init = common_init_from_params(params);
    if (llama_init == nullptr)
    {
        LOG_ERROR("unable to initialize model context: %s", params.model.path.c_str());
        return false;
    }
    model = llama_init->model();
    ctx = llama_init->context();
    if (model == nullptr)
    {
        LOG_ERROR("unable to load model: %s", params.model.path.c_str());
        return false;
    }
    if (ctx == nullptr)
    {
        LOG_ERROR("unable to create context: %s", params.model.path.c_str());
        return false;
    }
    templates = common_chat_templates_init(model, params.chat_template);
    n_ctx = llama_n_ctx(ctx);

    return true;
}

bool llama_mobile_context::validateModelChatTemplate(bool use_jinja, const char *name) const {
    const char * tmpl = llama_model_chat_template(model, name);
    if (tmpl == nullptr) {
      return false;
    }
    return common_chat_verify_template(tmpl, use_jinja);
}

const std::vector<lm_ggml_type> kv_cache_types = {
    LM_GGML_TYPE_F32,
    LM_GGML_TYPE_F16,
    LM_GGML_TYPE_BF16,
    LM_GGML_TYPE_Q8_0,
    LM_GGML_TYPE_Q4_0,
    LM_GGML_TYPE_Q4_1,
    LM_GGML_TYPE_IQ4_NL,
    LM_GGML_TYPE_Q5_0,
    LM_GGML_TYPE_Q5_1,
};

lm_ggml_type kv_cache_type_from_str(const std::string & s) {
    for (const auto & type : kv_cache_types) {
        if (lm_ggml_type_name(type) == s) {
            return type;
        }
    }
    throw std::runtime_error("Unsupported cache type: " + s);
}

} // namespace llama_mobile 