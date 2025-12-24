#include "llama-kv-cache-iswa.h"
#include "llama-impl.h"
#include "llama-io.h"
#include "llama-model.h"
#include "llama-context.h"

#include <algorithm>
#include <cassert>
#include <cstring>
#include <limits>
#include <map>
#include <stdexcept>

//
// llama_kv_cache_iswa
//

llama_kv_cache_iswa::llama_kv_cache_iswa(
        const llama_model & model,
                lm_ggml_type   type_k,
                lm_ggml_type   type_v,
                     bool   v_trans,
                     bool   offload,
                     bool   swa_full,
                     bool   unified,
                 uint32_t   kv_size,
                 uint32_t   n_seq_max,
                 uint32_t   n_ubatch,
                 uint32_t   n_pad,
    const layer_filter_cb & filter,
    const  layer_reuse_cb & reuse) :
    hparams(model.hparams), unified(unified) {

    // Create filter functions for non-SWA and SWA layers
    layer_filter_cb filter_base = [filter, this](int32_t il) {
        return (filter ? filter(il) : true) && !hparams.is_swa(il);
    };

    layer_filter_cb filter_swa = [filter, this](int32_t il) {
        return (filter ? filter(il) : true) && hparams.is_swa(il);
    };

    // Create reuse functions for non-SWA and SWA layers
    layer_reuse_cb reuse_base = [reuse](int32_t il) {
        return reuse ? reuse(il) : il;
    };

    layer_reuse_cb reuse_swa = [reuse](int32_t il) {
        return reuse ? reuse(il) : il;
    };

    // Create base kv cache for non-SWA layers
    kv_base = std::make_unique<llama_kv_cache>(
        model, type_k, type_v, v_trans, offload, unified, kv_size, n_seq_max, n_pad, 
        hparams.n_swa, hparams.swa_type, filter_base, reuse_base);

    // Create swa kv cache for SWA layers
    kv_swa = std::make_unique<llama_kv_cache>(
        model, type_k, type_v, v_trans, offload, unified, kv_size, n_seq_max, n_pad, 
        hparams.n_swa, hparams.swa_type, filter_swa, reuse_swa);
}

//
// llama_memory_i implementation
//

llama_memory_context_ptr llama_kv_cache_iswa::init_batch(
        llama_batch_allocr & balloc,
        uint32_t n_ubatch,
        bool embd_all) {
    // Not implemented yet
    return nullptr;
}

llama_memory_context_ptr llama_kv_cache_iswa::init_full() {
    return std::make_unique<llama_kv_cache_iswa_context>(this);
}

llama_memory_context_ptr llama_kv_cache_iswa::init_update(llama_context * lctx, bool optimize) {
    return std::make_unique<llama_kv_cache_iswa_context>(this, lctx, optimize);
}

bool llama_kv_cache_iswa::get_can_shift() const {
    return kv_base->get_can_shift() && kv_swa->get_can_shift();
}

void llama_kv_cache_iswa::clear(bool data) {
    kv_base->clear(data);
    kv_swa->clear(data);
}

bool llama_kv_cache_iswa::seq_rm(llama_seq_id seq_id, llama_pos p0, llama_pos p1) {
    return kv_base->seq_rm(seq_id, p0, p1) && kv_swa->seq_rm(seq_id, p0, p1);
}

void llama_kv_cache_iswa::seq_cp(llama_seq_id seq_id_src, llama_seq_id seq_id_dst, llama_pos p0, llama_pos p1) {
    kv_base->seq_cp(seq_id_src, seq_id_dst, p0, p1);
    kv_swa->seq_cp(seq_id_src, seq_id_dst, p0, p1);
}

void llama_kv_cache_iswa::seq_keep(llama_seq_id seq_id) {
    kv_base->seq_keep(seq_id);
    kv_swa->seq_keep(seq_id);
}

void llama_kv_cache_iswa::seq_add(llama_seq_id seq_id, llama_pos p0, llama_pos p1, llama_pos shift) {
    kv_base->seq_add(seq_id, p0, p1, shift);
    kv_swa->seq_add(seq_id, p0, p1, shift);
}

void llama_kv_cache_iswa::seq_div(llama_seq_id seq_id, llama_pos p0, llama_pos p1, int d) {
    kv_base->seq_div(seq_id, p0, p1, d);
    kv_swa->seq_div(seq_id, p0, p1, d);
}

llama_pos llama_kv_cache_iswa::seq_pos_min(llama_seq_id seq_id) const {
    return std::min(kv_base->seq_pos_min(seq_id), kv_swa->seq_pos_min(seq_id));
}

llama_pos llama_kv_cache_iswa::seq_pos_max(llama_seq_id seq_id) const {
    return std::max(kv_base->seq_pos_max(seq_id), kv_swa->seq_pos_max(seq_id));
}

std::map<lm_ggml_backend_buffer_type_t, size_t> llama_kv_cache_iswa::memory_breakdown() const {
    auto breakdown = kv_base->memory_breakdown();
    auto breakdown_swa = kv_swa->memory_breakdown();
    
    for (const auto & [buft, size] : breakdown_swa) {
        breakdown[buft] += size;
    }
    
    return breakdown;
}

void llama_kv_cache_iswa::state_write(llama_io_write_i & io, llama_seq_id seq_id, llama_state_seq_flags flags) const {
    kv_base->state_write(io, seq_id, flags);
    kv_swa->state_write(io, seq_id, flags);
}

void llama_kv_cache_iswa::state_read(llama_io_read_i & io, llama_seq_id seq_id, llama_state_seq_flags flags) {
    kv_base->state_read(io, seq_id, flags);
    kv_swa->state_read(io, seq_id, flags);
}

//
// llama_kv_cache_iswa specific API
//

llama_kv_cache * llama_kv_cache_iswa::get_base() const {
    return kv_base.get();
}

llama_kv_cache * llama_kv_cache_iswa::get_swa() const {
    return kv_swa.get();
}

//
// llama_kv_cache_iswa_context
//

llama_kv_cache_iswa_context::llama_kv_cache_iswa_context(llama_memory_status status) :
    status(status), ctx_base(nullptr), ctx_swa(nullptr) {
}

llama_kv_cache_iswa_context::llama_kv_cache_iswa_context(
        llama_kv_cache_iswa * kv) :
    status(LLAMA_MEMORY_STATUS_SUCCESS),
    ctx_base(kv->get_base()->init_full()),
    ctx_swa(kv->get_swa()->init_full()) {
}

llama_kv_cache_iswa_context::llama_kv_cache_iswa_context(
        llama_kv_cache_iswa * kv,
        llama_context * lctx,
        bool optimize) :
    status(LLAMA_MEMORY_STATUS_SUCCESS),
    ctx_base(kv->get_base()->init_update(lctx, optimize)),
    ctx_swa(kv->get_swa()->init_update(lctx, optimize)) {
}

llama_kv_cache_iswa_context::llama_kv_cache_iswa_context(
        llama_kv_cache_iswa * kv,
        slot_info_vec_t sinfos_base,
        slot_info_vec_t sinfos_swa,
        std::vector<llama_ubatch> ubatches) :
    ubatches(ubatches), status(LLAMA_MEMORY_STATUS_SUCCESS),
    ctx_base(nullptr), ctx_swa(nullptr) {
    // Not implemented yet
}

llama_kv_cache_iswa_context::~llama_kv_cache_iswa_context() {
}

//
// llama_memory_context_i implementation
//

bool llama_kv_cache_iswa_context::next() {
    if (i_next >= ubatches.size()) {
        return false;
    }
    
    bool base_next = ctx_base ? ctx_base->next() : true;
    bool swa_next = ctx_swa ? ctx_swa->next() : true;
    
    if (base_next && swa_next) {
        ++i_next;
        return true;
    }
    
    return false;
}

bool llama_kv_cache_iswa_context::apply() {
    bool base_apply = ctx_base ? ctx_base->apply() : true;
    bool swa_apply = ctx_swa ? ctx_swa->apply() : true;
    
    return base_apply && swa_apply;
}

llama_memory_status llama_kv_cache_iswa_context::get_status() const {
    return status;
}

const llama_ubatch & llama_kv_cache_iswa_context::get_ubatch() const {
    static llama_ubatch empty_ubatch;
    return i_next < ubatches.size() ? ubatches[i_next] : empty_ubatch;
}

//
// llama_kv_cache_iswa_context specific API
//

const llama_kv_cache_context * llama_kv_cache_iswa_context::get_base() const {
    return static_cast<const llama_kv_cache_context *>(ctx_base.get());
}

const llama_kv_cache_context * llama_kv_cache_iswa_context::get_swa() const {
    return static_cast<const llama_kv_cache_context *>(ctx_swa.get());
}
