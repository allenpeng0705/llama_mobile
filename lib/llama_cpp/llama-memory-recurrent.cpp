#include "llama-memory-recurrent.h"
#include "llama-model.h"

llama_memory_recurrent::llama_memory_recurrent(
        const llama_model & model,
                lm_ggml_type   type_r,
                lm_ggml_type   type_s,
                     bool   offload,
                 uint32_t   mem_size,
                 uint32_t   n_seq_max,
    const layer_filter_cb & filter)
    : hparams(model.hparams),
      n_seq_max(n_seq_max)
{
}

llama_memory_context_ptr llama_memory_recurrent::init_batch(
        llama_batch_allocr & balloc,
        uint32_t n_ubatch,
        bool embd_all)
{
    return std::make_unique<llama_memory_recurrent_context>(LLAMA_MEMORY_STATUS_SUCCESS);
}

llama_memory_context_ptr llama_memory_recurrent::init_full()
{
    return std::make_unique<llama_memory_recurrent_context>(LLAMA_MEMORY_STATUS_SUCCESS);
}

llama_memory_context_ptr llama_memory_recurrent::init_update(llama_context * lctx, bool optimize)
{
    return std::make_unique<llama_memory_recurrent_context>(LLAMA_MEMORY_STATUS_SUCCESS);
}

void llama_memory_recurrent::clear(bool data)
{
}

bool llama_memory_recurrent::seq_rm(llama_seq_id seq_id, llama_pos p0, llama_pos p1)
{
    return false;
}

void llama_memory_recurrent::seq_cp(llama_seq_id seq_id_src, llama_seq_id seq_id_dst, llama_pos p0, llama_pos p1)
{
}

void llama_memory_recurrent::seq_keep(llama_seq_id seq_id)
{
}

void llama_memory_recurrent::seq_add(llama_seq_id seq_id, llama_pos p0, llama_pos p1, llama_pos shift)
{
}

void llama_memory_recurrent::seq_div(llama_seq_id seq_id, llama_pos p0, llama_pos p1, int d)
{
}

llama_pos llama_memory_recurrent::seq_pos_min(llama_seq_id seq_id) const
{
    return 0;
}

llama_pos llama_memory_recurrent::seq_pos_max(llama_seq_id seq_id) const
{
    return 0;
}

std::map<lm_ggml_backend_buffer_type_t, size_t> llama_memory_recurrent::memory_breakdown() const
{
    return {};
}

bool llama_memory_recurrent::prepare(const std::vector<llama_ubatch> & ubatches)
{
    return true;
}

bool llama_memory_recurrent::find_slot(const llama_ubatch & ubatch)
{
    return true;
}

bool llama_memory_recurrent::get_can_shift() const
{
    return false;
}

void llama_memory_recurrent::state_write(llama_io_write_i & io, llama_seq_id seq_id, llama_state_seq_flags flags) const
{
}

void llama_memory_recurrent::state_read(llama_io_read_i & io, llama_seq_id seq_id, llama_state_seq_flags flags)
{
}

size_t llama_memory_recurrent::total_size() const
{
    return 0;
}

size_t llama_memory_recurrent::size_r_bytes() const
{
    return 0;
}

size_t llama_memory_recurrent::size_s_bytes() const
{
    return 0;
}

void llama_memory_recurrent::state_write_meta(llama_io_write_i & io, const std::vector<std::pair<uint32_t, uint32_t>> & cell_ranges, llama_seq_id seq_id) const
{
}

void llama_memory_recurrent::state_write_data(llama_io_write_i & io, const std::vector<std::pair<uint32_t, uint32_t>> & cell_ranges) const
{
}

bool llama_memory_recurrent::state_read_meta(llama_io_read_i & io, uint32_t cell_count, llama_seq_id dest_seq_id)
{
    return true;
}

bool llama_memory_recurrent::state_read_data(llama_io_read_i & io, uint32_t cell_count)
{
    return true;
}

// llama_memory_recurrent_context implementation

llama_memory_recurrent_context::llama_memory_recurrent_context(llama_memory_status status)
    : status(status), mem(nullptr), is_full(false)
{
}

llama_memory_recurrent_context::llama_memory_recurrent_context(llama_memory_recurrent * mem)
    : status(LLAMA_MEMORY_STATUS_SUCCESS), mem(mem), is_full(true)
{
}

llama_memory_recurrent_context::llama_memory_recurrent_context(llama_memory_recurrent * mem, std::vector<llama_ubatch> ubatches)
    : status(LLAMA_MEMORY_STATUS_SUCCESS), mem(mem), ubatches(std::move(ubatches)), is_full(false)
{
}

llama_memory_recurrent_context::~llama_memory_recurrent_context()
{
}

bool llama_memory_recurrent_context::next()
{
    return false;
}

bool llama_memory_recurrent_context::apply()
{
    return false;
}

llama_memory_status llama_memory_recurrent_context::get_status() const
{
    return status;
}

const llama_ubatch & llama_memory_recurrent_context::get_ubatch() const
{
    static llama_ubatch empty;
    return empty;
}

uint32_t llama_memory_recurrent_context::get_n_rs() const
{
    return 0;
}

uint32_t llama_memory_recurrent_context::get_head() const
{
    return 0;
}

int32_t llama_memory_recurrent_context::get_rs_z() const
{
    return 0;
}

uint32_t llama_memory_recurrent_context::get_size() const
{
    return 0;
}

lm_ggml_tensor * llama_memory_recurrent_context::get_r_l(int32_t il) const
{
    return nullptr;
}

lm_ggml_tensor * llama_memory_recurrent_context::get_s_l(int32_t il) const
{
    return nullptr;
}

int32_t llama_memory_recurrent_context::s_copy(int i) const
{
    return 0;
}
