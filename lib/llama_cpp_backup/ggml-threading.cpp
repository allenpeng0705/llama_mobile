#include "ggml-threading.h"
#include <mutex>

std::mutex ggml_critical_section_mutex;

void lm_ggml_critical_section_start() {
    ggml_critical_section_mutex.lock();
}

void lm_ggml_critical_section_end(void) {
    ggml_critical_section_mutex.unlock();
}
