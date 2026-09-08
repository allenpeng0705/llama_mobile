// utils.h — small helpers for the v2 C++ examples (no v1 APIs, no platform
// quirks). Paths/models come from argv; a few convenience helpers only.
#ifndef LLAMA_MOBILE_EXAMPLES_UTILS_H
#define LLAMA_MOBILE_EXAMPLES_UTILS_H

#include <string>
#include <vector>
#include <fstream>
#include <cmath>
#include <cstdlib>

namespace lmex {

inline bool file_exists(const std::string & path) {
    std::ifstream f(path, std::ios::binary);
    return f.good();
}

inline std::string arg_or(int argc, char ** argv, int i,
                          const std::string & fallback) {
    return i < argc ? std::string(argv[i]) : fallback;
}

// First existing candidate model dir; used when no explicit path is given.
inline std::string find_model_dir() {
    const char * env = std::getenv("LLAMA_MOBILE_MODELS_DIR");
    const std::vector<std::string> candidates = {
        env ? env : "",
        "./models",
        "../models",
        "../../models",
        "../../../models",
    };
    for (const auto & c : candidates) {
        if (!c.empty() && file_exists(c)) return c;
    }
    return "";
}

inline double dot(const std::vector<float> & a, const std::vector<float> & b) {
    double sum = 0;
    const size_t n = std::min(a.size(), b.size());
    for (size_t i = 0; i < n; ++i) sum += (double) a[i] * b[i];
    return sum;
}

inline double norm(const std::vector<float> & a) {
    return std::sqrt(dot(a, a));
}

// Minimal 16-bit mono WAV writer (for the TTS example's optional output).
inline bool write_wav(const std::string & path, const int16_t * pcm,
                      size_t n_samples, int sample_rate) {
    std::ofstream f(path, std::ios::binary);
    if (!f) return false;
    uint32_t data_bytes = (uint32_t) (n_samples * 2);
    uint32_t byte_rate = (uint32_t) sample_rate * 2;
    auto put32 = [&](uint32_t v) { f.write((const char *) &v, 4); };
    auto put16 = [&](uint16_t v) { f.write((const char *) &v, 2); };
    f.write("RIFF", 4); put32(36 + data_bytes); f.write("WAVE", 4);
    f.write("fmt ", 4); put32(16); put16(1); put16(1);
    put32((uint32_t) sample_rate); put32(byte_rate); put16(2); put16(16);
    f.write("data", 4); put32(data_bytes);
    f.write((const char *) pcm, data_bytes);
    return true;
}

} // namespace lmex

#endif // LLAMA_MOBILE_EXAMPLES_UTILS_H
