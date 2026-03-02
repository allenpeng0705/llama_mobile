#include "llama_mobile.h"
#include "llama.cpp-master/common/common.h"
#include "llama.cpp-master/include/llama.h"
#include <vector>
#include <cstdio>

namespace llama_mobile {

std::vector<float> llama_mobile_context::getEmbedding(common_params &embd_params) 
{
    if (!ctx || !model) {
        LOG_ERROR("Context or model not initialized for embedding generation.");
        return {};
    }
    
    const int n_embd = llama_model_n_embd_out(model);
    if (!params.embedding)
    {
        LOG_WARNING("Embedding mode not enabled for this context.");
        return std::vector<float>(n_embd, 0.0f);
    }

    const enum llama_pooling_type pooling_type = llama_pooling_type(ctx);
    
    llama_memory_clear(llama_get_memory(ctx), true);

    std::vector<llama_token> tokens = common_tokenize(ctx, embd_params.prompt, true, true);
    
    if (tokens.empty()) {
        LOG_WARNING("No tokens to process for embedding.");
        return std::vector<float>(n_embd, 0.0f);
    }

    llama_batch batch = llama_batch_init(tokens.size(), 0, 1);
    
    for (size_t i = 0; i < tokens.size(); i++) {
        common_batch_add(batch, tokens[i], i, {0}, true);
    }

    if (llama_decode(ctx, batch) < 0) {
        LOG_ERROR("Failed to decode batch for embedding.");
        llama_batch_free(batch);
        return std::vector<float>(n_embd, 0.0f);
    }

    const float *embd = nullptr;
    if (pooling_type == LLAMA_POOLING_TYPE_NONE) {
        embd = llama_get_embeddings_ith(ctx, tokens.size() - 1);
    } else {
        embd = llama_get_embeddings_seq(ctx, 0);
    }

    std::vector<float> result;
    if (embd) {
        result.resize(n_embd);
        common_embd_normalize(embd, result.data(), n_embd, embd_params.embd_normalize);
    } else {
        LOG_WARNING("Failed to retrieve embeddings from llama context.");
        result.resize(n_embd, 0.0f);
    }

    llama_batch_free(batch);
    return result;
}

} // namespace llama_mobile
