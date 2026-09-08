// main_tts.cpp — llama_mobile v2 TTS example (C API).
//
// Opens a TTS-capable main GGUF (e.g. OuteTTS-0.2-500M) as the context model,
// attaches the vocoder with llama_mobile_tts_init, synthesizes full text with
// llama_mobile_tts_speak (honoring sample_rate/speed) and optionally writes the
// PCM to a WAV file.
//
// Usage: ./llama_mobile_tts <main_tts.gguf> <vocoder.gguf> [out.wav]
//   (main defaults to OuteTTS-0.2-500M-Q6_K.gguf, vocoder to
//    WavTokenizer-Large-75-F16.gguf under ../../models)
#include <cstdio>
#include <iostream>
#include <string>

#include "llama_mobile_v2.h"
#include "utils.h"

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();
    const std::string model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/OuteTTS-0.2-500M-Q6_K.gguf");
    const std::string vocoder = lmex::arg_or(
        argc, argv, 2, dir.empty() ? "" : dir + "/WavTokenizer-Large-75-F16.gguf");
    const std::string wav_out = lmex::arg_or(argc, argv, 3, "");

    if (!lmex::file_exists(model) || !lmex::file_exists(vocoder)) {
        std::cerr << "usage: " << argv[0] << " <main_tts.gguf> <vocoder.gguf> [out.wav]\n"
                  << "missing: " << (lmex::file_exists(model) ? "" : model)
                  << (lmex::file_exists(vocoder) ? "" : " " + vocoder) << "\n";
        return 2;
    }

    llama_mobile_context_config_t cfg;
    llama_mobile_context_config_init(&cfg);
    cfg.model_path = model.c_str();
    cfg.engine = LLAMA_MOBILE_ENGINE_CPU;

    llama_mobile_context_t ctx = nullptr;
    llama_mobile_status_t st = llama_mobile_context_create(&cfg, &ctx);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "context create failed: " << llama_mobile_status_string(st) << "\n";
        return 1;
    }

    st = llama_mobile_tts_init(ctx, vocoder.c_str());
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "tts_init failed: " << llama_mobile_status_string(st) << "\n";
        llama_mobile_context_destroy(&ctx);
        return 1;
    }
    std::cout << "TTS enabled: " << (llama_mobile_tts_is_enabled(ctx) ? "yes" : "no") << "\n";

    llama_mobile_tts_params_t tp;
    llama_mobile_tts_params_init(&tp);
    tp.text = "Hello from llama mobile. On-device speech synthesis works.";
    tp.sample_rate = 24000;
    tp.speed = 1.0f;

    int16_t * pcm = nullptr;
    size_t pcm_len = 0;
    llama_mobile_usage_t usage;
    st = llama_mobile_tts_speak(ctx, &tp, &usage, &pcm, &pcm_len);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "tts_speak failed: " << llama_mobile_status_string(st) << "\n";
        llama_mobile_tts_release(ctx);
        llama_mobile_context_destroy(&ctx);
        return 1;
    }
    const double secs = (double) pcm_len / (double) tp.sample_rate;
    std::printf("synthesized %zu samples = %.2f s at %d Hz\n",
                pcm_len, secs, tp.sample_rate);
    if (pcm_len > 0) {
        std::printf("first sample: %d\n", pcm[0]);
    }
    if (!wav_out.empty() && lmex::write_wav(wav_out, pcm, pcm_len, tp.sample_rate)) {
        std::cout << "wrote " << wav_out << "\n";
    }
    llama_mobile_tts_pcm_free(pcm);

    llama_mobile_tts_release(ctx);
    llama_mobile_context_destroy(&ctx);
    return 0;
}
