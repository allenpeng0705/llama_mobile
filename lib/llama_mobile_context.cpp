#include "llama_mobile.h"
#include "llama_cpp/common.h"
#include "llama_cpp/nlohmann/json.hpp"
#include "llama_cpp/llama-sampling.h"
#include <regex>

using json = nlohmann::ordered_json;

namespace llama_mobile {

llama_mobile_context::~llama_mobile_context() {
    if (ctx_sampling != nullptr) {
        common_sampler_free(ctx_sampling);
        ctx_sampling = nullptr;
    }
    releaseMultimodal();
    releaseVocoder();
}

void llama_mobile_context::rewind() {
    is_interrupted = false;
    is_predicting = false;
    params.antiprompt.clear();
    params.sampling.grammar.clear();
    num_prompt_tokens = 0;
    num_tokens_predicted = 0;
    generated_text = "";
    generated_text.reserve(params.n_ctx);
    generated_token_probs.clear();
    truncated = false;
    context_full = false;
    stopped_eos = false;
    stopped_word = false;
    stopped_limit = false;
    stopping_word = "";
    incomplete = false;
    n_remain = 0;
    n_past = 0;
    embd.clear();
    next_token_uses_guide_token = false;
    guide_tokens.clear();
    mtmd_bitmap_past_hashes.clear();
    audio_tokens.clear();
    if (ctx_sampling) {
    }
}

bool llama_mobile_context::initSampling() {
    if (ctx_sampling != nullptr) {
        common_sampler_free(ctx_sampling);
        ctx_sampling = nullptr;
    }
    if (model) {
        ctx_sampling = common_sampler_init(model, params.sampling);
        if (ctx_sampling) {
             params.sampling.n_prev = n_ctx;
        }
    } else {
        LOG_ERROR("Cannot initialize sampling context: model is not loaded.");
        return false;
    }
    return ctx_sampling != nullptr;
}

void llama_mobile_context::setGuideTokens(const std::vector<llama_token> &tokens) {
    guide_tokens = tokens;
}

void llama_mobile_context::endCompletion() {
    is_predicting = false;
}

std::string llama_mobile_context::generateResponse(const std::string &user_message, int max_tokens) {
    auto result = continueConversation(user_message, max_tokens);
    return result.text;
}

conversation_result llama_mobile_context::continueConversation(const std::string &user_message, int max_tokens) {
    auto start_time = std::chrono::high_resolution_clock::now();
    
    if (!model || !ctx) {
        LOG_ERROR("Model or context not initialized");
        return {"", std::chrono::milliseconds(0), std::chrono::milliseconds(0), 0};
    }

    bool is_first_message = !conversation_active || embd.empty();
    
    if (is_first_message) {
        // First message in conversation - use standard chat formatting
        json messages = json::array();
        
        // Add system prompt if available
        if (!params.system_prompt.empty()) {
            messages.push_back({
                {"role", "system"},
                {"content", params.system_prompt}
            });
        }
        
        // Add user message
        messages.push_back({
            {"role", "user"},
            {"content", user_message}
        });
        
        // Add empty assistant message to trigger assistant role start token in template
        messages.push_back({
            {"role", "assistant"},
            {"content", ""}
        });
        
        std::string formatted_prompt;
        try {
            formatted_prompt = getFormattedChat(messages.dump(), "");
            last_chat_template = formatted_prompt;
        } catch (const std::exception& e) {
            LOG_ERROR("Chat template formatting failed: %s", e.what());
            formatted_prompt = "User: " + user_message + "\nAssistant: ";
            last_chat_template = formatted_prompt;
        }
        
        // Set up for generation
        params.prompt = formatted_prompt;
        params.n_predict = max_tokens;
        
        if (!initSampling()) {
            LOG_ERROR("Failed to initialize sampling");
            return {"", std::chrono::milliseconds(0), std::chrono::milliseconds(0), 0};
        }
        
        beginCompletion();
        loadPrompt();
        
        conversation_active = true;
    } else {
        // Continuing conversation - append only the new user message
        json messages = json::array();
        messages.push_back({
            {"role", "user"}, 
            {"content", user_message}
        });
        
        std::string user_part;
        try {
            user_part = getFormattedChat(messages.dump(), "");
            // Extract just the user message part by removing the assistant start
            size_t assistant_start = user_part.find("<|im_start|>assistant");
            if (assistant_start != std::string::npos) {
                user_part = user_part.substr(0, assistant_start) + "<|im_start|>assistant\n";
            }
        } catch (const std::exception& e) {
            LOG_ERROR("Chat template formatting failed: %s", e.what());
            user_part = "\n<|im_start|>user\n" + user_message + "<|im_end|>\n<|im_start|>assistant\n";
        }
        
        // Tokenize only the new user message part
        std::vector<llama_token> new_tokens = common_tokenize(ctx, user_part, false, true);
        
        // Append to existing conversation
        embd.insert(embd.end(), new_tokens.begin(), new_tokens.end());
        
        // Set up generation parameters
        params.n_predict = max_tokens;
        n_remain = max_tokens;
        has_next_token = true;
        is_predicting = true;
        generated_text.clear();
        
        // Initialize sampling if needed
        if (!initSampling()) {
            LOG_ERROR("Failed to initialize sampling");
            return {"", std::chrono::milliseconds(0), std::chrono::milliseconds(0), 0};
        }
        
        // Accept the new tokens in the sampler
        for (auto token : new_tokens) {
            common_sampler_accept(ctx_sampling, token, false);
        }
    }
    
    // Generate the response with timing tracking
    bool first_token = true;
    std::chrono::high_resolution_clock::time_point first_token_time;
    int tokens_generated = 0;
    
    while (has_next_token && !is_interrupted) {
        auto token_output = doCompletion();
        if (token_output.tok == -1) break;
        
        if (first_token) {
            first_token_time = std::chrono::high_resolution_clock::now();
            first_token = false;
        }
        tokens_generated++;
    }
    
    auto end_time = std::chrono::high_resolution_clock::now();
    
    endCompletion();
    
    auto total_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
    auto ttft = first_token ? std::chrono::milliseconds(0) : 
                std::chrono::duration_cast<std::chrono::milliseconds>(first_token_time - start_time);
    
    LOG_VERBOSE("Generated response: %s (TTFT: %dms, Total: %dms, Tokens: %d)", 
                generated_text.c_str(), (int)ttft.count(), (int)total_time.count(), tokens_generated);
    
    return {generated_text, ttft, total_time, tokens_generated};
}

void llama_mobile_context::clearConversation() {
    conversation_active = false;
    last_chat_template.clear();
    rewind();
    LOG_VERBOSE("Conversation cleared");
}

bool llama_mobile_context::isConversationActive() const {
    return conversation_active;
}

// TTS implementation

namespace {
    // Default audio template data
    static const std::string default_audio_text = "<|text_start|>the<|text_sep|>overall<|text_sep|>package<|text_sep|>from<|text_sep|>just<|text_sep|>two<|text_sep|>people<|text_sep|>is<|text_sep|>pretty<|text_sep|>remarkable<|text_sep|>sure<|text_sep|>i<|text_sep|>have<|text_sep|>some<|text_sep|>critiques<|text_sep|>about<|text_sep|>some<|text_sep|>of<|text_sep|>the<|text_sep|>gameplay<|text_sep|>aspects<|text_sep|>but<|text_sep|>its<|text_sep|>still<|text_sep|>really<|text_sep|>enjoyable<|text_sep|>and<|text_sep|>it<|text_sep|>looks<|text_sep|>lovely<|text_sep|>";

    static const std::string default_audio_data = R"(<|audio_start|>
the<|t_0.08|><|code_start|><|257|><|740|><|636|><|913|><|788|><|1703|><|code_end|>
overall<|t_0.36|><|code_start|><|127|><|201|><|191|><|774|><|700|><|532|><|1056|><|557|><|798|><|298|><|1741|><|747|><|1662|><|1617|><|1702|><|1527|><|368|><|1588|><|1049|><|1008|><|1625|><|747|><|1576|><|728|><|1019|><|1696|><|1765|><|code_end|>
package<|t_0.56|><|code_start|><|935|><|584|><|1319|><|627|><|1016|><|1491|><|1344|><|1117|><|1526|><|1040|><|239|><|1435|><|951|><|498|><|723|><|1180|><|535|><|789|><|1649|><|1637|><|78|><|465|><|1668|><|901|><|595|><|1675|><|117|><|1009|><|1667|><|320|><|840|><|79|><|507|><|1762|><|1508|><|1228|><|1768|><|802|><|1450|><|1457|><|232|><|639|><|code_end|>
from<|t_0.19|><|code_start|><|604|><|782|><|1682|><|872|><|1532|><|1600|><|1036|><|1761|><|647|><|1554|><|1371|><|653|><|1595|><|950|><|code_end|>
just<|t_0.25|><|code_start|><|1782|><|1670|><|317|><|786|><|1748|><|631|><|599|><|1155|><|1364|><|1524|><|36|><|1591|><|889|><|1535|><|541|><|440|><|1532|><|50|><|870|><|code_end|>
two<|t_0.24|><|code_start|><|1681|><|1510|><|673|><|799|><|805|><|1342|><|330|><|519|><|62|><|640|><|1138|><|565|><|1552|><|1497|><|1552|><|572|><|1715|><|1732|><|code_end|>
people<|t_0.39|><|code_start|><|593|><|274|><|136|><|740|><|691|><|633|><|1484|><|1061|><|1138|><|1485|><|344|><|428|><|397|><|1562|><|645|><|917|><|1035|><|1449|><|1669|><|487|><|442|><|1484|><|1329|><|1832|><|1704|><|600|><|761|><|653|><|269|><|code_end|>
is<|t_0.16|><|code_start|><|566|><|583|><|1755|><|646|><|1337|><|709|><|802|><|1008|><|485|><|1583|><|652|><|10|><|code_end|>
pretty<|t_0.32|><|code_start|><|1818|><|1747|><|692|><|733|><|1010|><|534|><|406|><|1697|><|1053|><|1521|><|1355|><|1274|><|816|><|1398|><|211|><|1218|><|817|><|1472|><|1703|><|686|><|13|><|822|><|445|><|1068|><|code_end|>
remarkable<|t_0.68|><|code_start|><|230|><|1048|><|1705|><|355|><|706|><|1149|><|1535|><|1787|><|1356|><|1396|><|835|><|1583|><|486|><|1249|><|286|><|937|><|1076|><|1150|><|614|><|42|><|1058|><|705|><|681|><|798|><|934|><|490|><|514|><|1399|><|572|><|1446|><|1703|><|1346|><|1040|><|1426|><|1304|><|664|><|171|><|1530|><|625|><|64|><|1708|><|1830|><|1030|><|443|><|1509|><|1063|><|1605|><|1785|><|721|><|1440|><|923|><|code_end|>
sure<|t_0.36|><|code_start|><|792|><|1780|><|923|><|1640|><|265|><|261|><|1525|><|567|><|1491|><|1250|><|1730|><|362|><|919|><|1766|><|543|><|1|><|333|><|113|><|970|><|252|><|1606|><|133|><|302|><|1810|><|1046|><|1190|><|1675|><|code_end|>
i<|t_0.08|><|code_start|><|123|><|439|><|1074|><|705|><|1799|><|637|><|code_end|>
have<|t_0.16|><|code_start|><|1509|><|599|><|518|><|1170|><|552|><|1029|><|1267|><|864|><|419|><|143|><|1061|><|0|><|code_end|>
some<|t_0.16|><|code_start|><|619|><|400|><|1270|><|62|><|1370|><|1832|><|917|><|1661|><|167|><|269|><|1366|><|1508|><|code_end|>
critiques<|t_0.60|><|code_start|><|559|><|584|><|1163|><|1129|><|1313|><|1728|><|721|><|1146|><|1093|><|577|><|928|><|27|><|630|><|1080|><|1346|><|1337|><|320|><|1382|><|1175|><|1682|><|1556|><|990|><|1683|><|860|><|1721|><|110|><|786|><|376|><|1085|><|756|><|1523|><|234|><|1334|><|1506|><|1578|><|659|><|612|><|1108|><|1466|><|1647|><|308|><|1470|><|746|><|556|><|1061|><|code_end|>
about<|t_0.29|><|code_start|><|26|><|1649|><|545|><|1367|><|1263|><|1728|><|450|><|859|><|1434|><|497|><|1220|><|1285|><|179|><|755|><|1154|><|779|><|179|><|1229|><|1213|><|922|><|1774|><|1408|><|code_end|>
some<|t_0.23|><|code_start|><|986|><|28|><|1649|><|778|><|858|><|1519|><|1|><|18|><|26|><|1042|><|1174|><|1309|><|1499|><|1712|><|1692|><|1516|><|1574|><|code_end|>
of<|t_0.07|><|code_start|><|197|><|716|><|1039|><|1662|><|64|><|code_end|>
the<|t_0.08|><|code_start|><|1811|><|1568|><|569|><|886|><|1025|><|1374|><|code_end|>
gameplay<|t_0.48|><|code_start|><|1269|><|1092|><|933|><|1362|><|1762|><|1700|><|1675|><|215|><|781|><|1086|><|461|><|838|><|1022|><|759|><|649|><|1416|><|1004|><|551|><|909|><|787|><|343|><|830|><|1391|><|1040|><|1622|><|1779|><|1360|><|1231|><|1187|><|1317|><|76|><|997|><|989|><|978|><|737|><|189|><|code_end|>
aspects<|t_0.56|><|code_start|><|1423|><|797|><|1316|><|1222|><|147|><|719|><|1347|><|386|><|1390|><|1558|><|154|><|440|><|634|><|592|><|1097|><|1718|><|712|><|763|><|1118|><|1721|><|1311|><|868|><|580|><|362|><|1435|><|868|><|247|><|221|><|886|><|1145|><|1274|><|1284|><|457|><|1043|><|1459|><|1818|><|62|><|599|><|1035|><|62|><|1649|><|778|><|code_end|>
but<|t_0.20|><|code_start|><|780|><|1825|><|1681|><|1007|><|861|><|710|><|702|><|939|><|1669|><|1491|><|613|><|1739|><|823|><|1469|><|648|><|code_end|>
its<|t_0.09|><|code_start|><|92|><|688|><|1623|><|962|><|1670|><|527|><|599|><|code_end|>
still<|t_0.27|><|code_start|><|636|><|10|><|1217|><|344|><|713|><|957|><|823|><|154|><|1649|><|1286|><|508|><|214|><|1760|><|1250|><|456|><|1352|><|1368|><|921|><|615|><|5|><|code_end|>
really<|t_0.36|><|code_start|><|55|><|420|><|1008|><|1659|><|27|><|644|><|1266|><|617|><|761|><|1712|><|109|><|1465|><|1587|><|503|><|1541|><|619|><|197|><|1019|><|817|><|269|><|377|><|362|><|1381|><|507|><|1488|><|4|><|1695|><|code_end|>
enjoyable<|t_0.49|><|code_start|><|678|><|501|><|864|><|319|><|288|><|1472|><|1341|><|686|><|562|><|1463|><|619|><|1563|><|471|><|911|><|730|><|1811|><|1006|><|520|><|861|><|1274|><|125|><|1431|><|638|><|621|><|153|><|876|><|1770|><|437|><|987|><|1653|><|1109|><|898|><|1285|><|80|><|593|><|1709|><|843|><|code_end|>
and<|t_0.15|><|code_start|><|1285|><|987|><|303|><|1037|><|730|><|1164|><|502|><|120|><|1737|><|1655|><|1318|><|code_end|>
it<|t_0.09|><|code_start|><|848|><|1366|><|395|><|1601|><|1513|><|593|><|1302|><|code_end|>
looks<|t_0.27|><|code_start|><|1281|><|1266|><|1755|><|572|><|248|><|1751|><|1257|><|695|><|1380|><|457|><|659|><|585|><|1315|><|1105|><|1776|><|736|><|24|><|736|><|654|><|1027|><|code_end|>
lovely<|t_0.56|><|code_start|><|634|><|596|><|1766|><|1556|><|1306|><|1285|><|1481|><|1721|><|1123|><|438|><|1246|><|1251|><|795|><|659|><|1381|><|1658|><|217|><|1772|><|562|><|952|><|107|><|1129|><|1112|><|467|><|550|><|1079|><|840|><|1615|><|1469|><|1380|><|168|><|917|><|836|><|1827|><|437|><|583|><|67|><|595|><|1087|><|1646|><|1493|><|1677|><|code_end|>)";
} // anonymous namespace

// Forward declarations for utility functions from llama_mobile_tts.cpp
std::string process_text(const std::string & text, const tts_type tts_version);
std::vector<float> embd_to_audio(const float * embd, const int n_codes, const int n_embd, const int n_thread);
bool save_wav16(const std::string & fname, const std::vector<float> & data, int sample_rate);

bool llama_mobile_context::initVocoder(const std::string &vocoder_model_path) {
    if (vocoder_wrapper != nullptr) {
        return true;
    }
    
    common_params vocoder_params = params;
    vocoder_params.model.path = vocoder_model_path;
    vocoder_params.embedding = true;
    vocoder_params.n_ubatch = vocoder_params.n_batch;

    llama_mobile_context_vocoder *wrapper = new llama_mobile_context_vocoder{
        .init_result = common_init_from_params(vocoder_params),
    };

    wrapper->model = wrapper->init_result->model();
    wrapper->ctx = wrapper->init_result->context();

    if (wrapper->model == nullptr || wrapper->ctx == nullptr) {
        LOG_ERROR("Failed to load vocoder model: %s", vocoder_model_path.c_str());
        delete wrapper;
        return false;
    }

    // Check vocab type immediately after loading
    const llama_vocab *vocab = llama_model_get_vocab(wrapper->model);
    if (vocab != nullptr) {
        enum llama_vocab_type vocab_type = llama_vocab_type(vocab);
        LOG_INFO("Vocoder model %s loaded with vocab type: %d", 
                vocoder_model_path.c_str(), vocab_type);
        
        if (vocab_type == LLAMA_VOCAB_TYPE_NONE) {
            LOG_WARNING("Vocoder model %s has no tokenizer (LLAMA_VOCAB_TYPE_NONE), guide tokens generation will be disabled", 
                      vocoder_model_path.c_str());
        }
    }

    // Determine TTS version based on model characteristics
    if (model) {
        const char *chat_template = llama_model_chat_template(model, nullptr);
        if (chat_template && std::string(chat_template) == "outetts-0.3") {
            wrapper->type = TTS_OUTETTS_V0_3;
        } else {
            wrapper->type = TTS_OUTETTS_V0_2;
        }
    } else {
        wrapper->type = TTS_OUTETTS_V0_2;
    }
    
    vocoder_wrapper = wrapper;
    has_vocoder = true;
    
    LOG_INFO("Vocoder initialized successfully with model: %s (TTS version: %d)", 
            vocoder_model_path.c_str(), wrapper->type);
    return true;
}

bool llama_mobile_context::isVocoderEnabled() const {
    return has_vocoder && vocoder_wrapper != nullptr;
}

void llama_mobile_context::releaseVocoder() {
    if (vocoder_wrapper != nullptr) {
        delete vocoder_wrapper;
        vocoder_wrapper = nullptr;
    }
    has_vocoder = false;
    audio_tokens.clear();
}

tts_type llama_mobile_context::getTTSType() const {
    if (vocoder_wrapper == nullptr) {
        return TTS_UNKNOWN;
    }
    
    if (vocoder_wrapper->type != TTS_UNKNOWN) {
        return vocoder_wrapper->type;
    }
    
    if (model) {
        const char *chat_template = llama_model_chat_template(model, nullptr);
        if (chat_template && std::string(chat_template) == "outetts-0.3") {
            return TTS_OUTETTS_V0_3;
        }
    }
    return TTS_OUTETTS_V0_2;
}

std::string llama_mobile_context::getFormattedAudioCompletion(const std::string &speaker_json_str, const std::string &text_to_speak) {
    if (!isVocoderEnabled()) {
        throw std::runtime_error("Vocoder is not enabled but audio completion is requested");
    }
    
    std::string audio_text = default_audio_text;
    std::string audio_data = default_audio_data;

    const tts_type type = getTTSType();
    if (type == TTS_UNKNOWN) {
        LOG_ERROR("Unknown TTS version");
        return "";
    }

    // Format audio text and data based on TTS version (same as main function)
    if (type == TTS_OUTETTS_V0_3) {
        audio_text = std::regex_replace(audio_text, std::regex(R"(<\|text_sep\|>)"), "<|space|>");
        audio_data = std::regex_replace(audio_data, std::regex(R"(<\|code_start\|>)"), "");
        audio_data = std::regex_replace(audio_data, std::regex(R"(<\|code_end\|>)"), "<|space|");
    }

    return "<|im_start|>\n" + audio_text + process_text(text_to_speak, type) + "<|text_end|>\n" + audio_data + "\n";
}

std::vector<llama_token> llama_mobile_context::getAudioCompletionGuideTokens(const std::string &text_to_speak) {
    if (!isVocoderEnabled()) {
        LOG_ERROR("Vocoder not enabled for guide token generation");
        return {};
    }
    
    // Use the main model's vocab for tokenization, not the vocoder's
    const llama_vocab * vocab = llama_model_get_vocab(model);
    enum llama_vocab_type vocab_type = llama_vocab_type(vocab);
    LOG_INFO("Main model vocab type: %d", vocab_type);
    
    // Check if tokenizer is initialized
    if (vocab_type == LLAMA_VOCAB_TYPE_NONE) {
        LOG_ERROR("Main TTS model has no tokenizer (type: %d), cannot generate guide tokens", vocab_type);
        return {};
    }
    
    const tts_type type = getTTSType();
    std::string clean_text = process_text(text_to_speak, type);

    const std::string& delimiter = (type == TTS_OUTETTS_V0_3 ? "<|space|>" : "<|text_sep|>");

    std::vector<llama_token> result;
    size_t start = 0;
    size_t end = clean_text.find(delimiter);

    result.push_back(common_tokenize(vocab, "\n", false, true)[0]);

    while (end != std::string::npos) {
        std::string current_word = clean_text.substr(start, end - start);
        auto tmp = common_tokenize(vocab, current_word, false, true);
        if (!tmp.empty()) {
            result.push_back(tmp[0]);
        }
        start = end + delimiter.length();
        end = clean_text.find(delimiter, start);
    }

    std::string current_word = clean_text.substr(start);
    auto tmp = common_tokenize(vocab, current_word, false, true);
    if (!tmp.empty()) {
        result.push_back(tmp[0]);
    }
    
    return result;
}

std::vector<float> llama_mobile_context::decodeAudioTokens(const std::vector<llama_token> &tokens) {
    if (!isVocoderEnabled()) {
        throw std::runtime_error("Vocoder is not enabled but audio decoding is requested");
    }
    
    std::vector<llama_token> tokens_audio = tokens;
    tts_type type = getTTSType();
    
    if (type == TTS_OUTETTS_V0_3 || type == TTS_OUTETTS_V0_2) {
        // Filter out non-audio tokens (same as main function)
        tokens_audio.erase(std::remove_if(tokens_audio.begin(), tokens_audio.end(), 
            [](llama_token t) { return t < 151672 || t > 155772; }), tokens_audio.end());
        
        // Adjust tokens for vocoder input (same as main function)
        for (auto & token : tokens_audio) {
            token -= 151672;
        }
    } else {
        LOG_ERROR("Unsupported audio token type");
        return std::vector<float>();
    }

    // Use the vocoder model for decoding (same as main function)
    llama_batch batch = llama_batch_init(tokens_audio.size(), 0, 1);
    for (size_t i = 0; i < tokens_audio.size(); ++i) {
        common_batch_add(batch, tokens_audio[i], i, { 0 }, true);
    }

    if (llama_encode(vocoder_wrapper->ctx, batch) != 0) {
        LOG_ERROR("Failed to encode audio tokens");
        return std::vector<float>();
    }

    const int n_embd = llama_model_n_embd(vocoder_wrapper->model);
    const float * embd = llama_get_embeddings(vocoder_wrapper->ctx);

    // Convert embeddings to audio using the same function as main
    auto audio = embd_to_audio(embd, tokens_audio.size(), n_embd, params.cpuparams.n_threads);

    return audio;
}

bool llama_mobile_context::saveAudioToWav(const std::string &file_path, const std::vector<float> &audio_data, int sample_rate) {
    if (audio_data.empty()) {
        LOG_ERROR("Cannot save empty audio data to WAV file");
        return false;
    }
    
    return save_wav16(file_path, audio_data, sample_rate);
}

} // namespace llama_mobile