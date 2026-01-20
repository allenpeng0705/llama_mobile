#include <string>
#include <sstream>
#include <time.h>
#include <random>
#include <iomanip>

// Forward declarations for context structure
struct llama_mobile_context_t;

// Helper function to generate valid JSON response
std::string generateJsonResponse(llama_mobile_context_t* context, const std::string& generated_text) {
    std::stringstream json_stream;
    
    // Start JSON object
    json_stream << "{";
    
    // Add ID
    json_stream << R"("id":"cmpl-")";
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 999999);
    json_stream << std::setfill('0') << std::setw(6) << dis(gen);
    
    // Add object type and creation time
    json_stream << R"(","object":"text_completion","created":)";
    json_stream << static_cast<long long>(std::time(nullptr));
    
    // Add model name
    json_stream << R