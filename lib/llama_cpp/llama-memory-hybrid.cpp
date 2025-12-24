#include "llama-memory-hybrid.h"

#include "llama-model.h"

// Implementation of llama_memory_hybrid

llama_memory_hybrid::llama_memory_hybrid(
    const llama_model & model,
    lm_ggml_type type_k, lm_ggml_type type_v, bool v_trans,
    uint32_t kv_size, uint32_t n_pad, uint32_t n_swa, llama_swa_type swa_type,
    lm_ggml_type type_r, lm_ggml_type type_s, uint32_t rs_size,
    uint32_t n_seq_max, bool offload, bool unified,
    const layer_filter_cb & filter_attn, const layer_filter_cb & filter_recr)
    : hparams(model.hparams),
      mem_attn(std::make_unique<llama_kv_cache>(model, type_k, type_v, v_trans, offload, unified, kv_size, n_seq_max, n_pad, n_swa, swa_type, filter_attn, nullptr)),
      mem_recr(std::make_unique<llama_memory_recurrent>(model, type_r, type_s, offload, rs_size, n_seq_max, filter_recr)) {
}

llama_memory_context_ptr llama_memory_hybrid::init_batch(llama_batch_allocr & balloc, uint32_t n_ubatch, bool embd_all) {
    // This is a placeholder implementation
    // In a real implementation, we would initialize both attention and recurrent contexts
    return nullptr;
}

llama_memory_context_ptr llama_memory_hybrid::init_full() {
    return std::make_unique<llama_memory_hybrid_context>(this);
}

llama_memory_context_ptr llama_memory_hybrid::init_update(llama_context * lctx, bool optimize) {
    return std::make_unique<llama_memory_hybrid_context>(this, lctx, optimize);
}

bool llama_memory_hybrid::get_can_shift() const {
    return mem_attn->get_can_shift();
}

void llama_memory_hybrid::clear(bool data) {
    mem_attn->clear(data);
    mem_recr->clear(data);
}

bool llama_memory_hybrid::seq_rm(llama_seq_id seq_id, llama_pos p0, llama_pos p1) {
    return mem_attn->seq_rm(seq_id, p0, p1) && mem_recr->seq_rm(seq_id, p0, p1);
}

void llama_memory_hybrid::seq_cp(llama_seq_id seq_id_src, llama_seq_id seq_id_dst, llama_pos p0, llama_pos p1) {
    mem_attn->seq_cp(seq_id_src, seq_id_dst, p0, p1);
    mem_recr->seq_cp(seq_id_src, seq_id_dst, p0, p1);
}

void llama_memory_hybrid::seq_keep(llama_seq_id seq_id) {
    mem_attn->seq_keep(seq_id);
    mem_recr->seq_keep(seq_id);
}

void llama_memory_hybrid::seq_add(llama_seq_id seq_id, llama_pos p0, llama_pos p1, llama_pos shift) {
    mem_attn->seq_add(seq_id, p0, p1, shift);
    mem_recr->seq_add(seq_id, p0, p1, shift);
}

void llama_memory_hybrid::seq_div(llama_seq_id seq_id, llama_pos p0, llama_pos p1, int d) {
    mem_attn->seq_div(seq_id, p0, p1, d);
    mem_recr->seq_div(seq_id, p0, p1, d);
}

llama_pos llama_memory_hybrid::seq_pos_min(llama_seq_id seq_id) const {
    return std::min(mem_attn->seq_pos_min(seq_id), mem_recr->seq_pos_min(seq_id));
}

llama_pos llama_memory_hybrid::seq_pos_max(llama_seq_id seq_id) const {
    return std::max(mem_attn->seq_pos_max(seq_id), mem_recr->seq_pos_max(seq_id));
}

std::map<lm_ggml_backend_buffer_type_t, size_t> llama_memory_hybrid::memory_breakdown() const {
    auto breakdown = mem_attn->memory_breakdown();
    auto recr_breakdown = mem_recr->memory_breakdown();
    
    for (const auto & [type, size] : recr_breakdown) {
        breakdown[type] += size;
    }
    
    return breakdown;
}

void llama_memory_hybrid::state_write(llama_io_write_i & io, llama_seq_id seq_id, llama_state_seq_flags flags) const {
    mem_attn->state_write(io, seq_id, flags);
    mem_recr->state_write(io, seq_id, flags);
}

void llama_memory_hybrid::state_read(llama_io_read_i & io, llama_seq_id seq_id, llama_state_seq_flags flags) {
    mem_attn->state_read(io, seq_id, flags);
    mem_recr->state_read(io, seq_id, flags);
}

llama_kv_cache * llama_memory_hybrid::get_mem_attn() const {
    return mem_attn.get();
}

llama_memory_recurrent * llama_memory_hybrid::get_mem_recr() const {
    return mem_recr.get();
}

// Implementation of llama_memory_hybrid_context

llama_memory_hybrid_context::llama_memory_hybrid_context(llama_memory_status status)
    : ctx_attn(nullptr), ctx_recr(nullptr), status(status) {
}

llama_memory_hybrid_context::llama_memory_hybrid_context(llama_memory_hybrid * mem)
    : ctx_attn(mem->get_mem_attn()->init_full()),
      ctx_recr(mem->get_mem_recr()->init_full()),
      status(LLAMA_MEMORY_STATUS_SUCCESS) {
}

llama_memory_hybrid_context::llama_memory_hybrid_context(
    llama_memory_hybrid * mem, llama_context * lctx, bool optimize)
    : ctx_attn(mem->get_mem_attn()->init_update(lctx, optimize)),
      ctx_recr(mem->get_mem_recr()->init_update(lctx, optimize)),
      status(LLAMA_MEMORY_STATUS_SUCCESS) {
}

llama_memory_hybrid_context::llama_memory_hybrid_context(
    llama_memory_hybrid * mem, slot_info_vec_t sinfos_attn, std::vector<llama_ubatch> ubatches)
    : ubatches(std::move(ubatches)),
      ctx_attn(nullptr), // We would initialize with sinfos_attn in a real implementation
      ctx_recr(nullptr), // This would be initialized properly in a real implementation
      status(LLAMA_MEMORY_STATUS_SUCCESS) {
}

bool llama_memory_hybrid_context::next() {
    // In a real implementation, we would manage the next batch
    return false;
}

bool llama_memory_hybrid_context::apply() {
    // In a real implementation, we would apply changes to both contexts
    return false;
}

llama_memory_status llama_memory_hybrid_context::get_status() const {
    return status;
}

const llama_ubatch & llama_memory_hybrid_context::get_ubatch() const {
    static llama_ubatch empty;
    return ubatches.empty() ? empty : ubatches[i_next];
}

const llama_kv_cache_context * llama_memory_hybrid_context::get_attn() const {
    // In a real implementation, this would cast to the correct type
    return nullptr;
}

const llama_memory_recurrent_context * llama_memory_hybrid_context::get_recr() const {
    // In a real implementation, this would cast to the correct type
    return nullptr;
}