#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <cmath>
#include <iomanip>
#include <algorithm>
#include <filesystem>

#include "utils.h"
#include "../../lib/llama_mobile.h"

namespace fs = std::filesystem;

float cosineSimilarity(const std::vector<float>& a, const std::vector<float>& b) {
    if (a.size() != b.size()) {
        std::cerr << "Error: Vector dimensions don't match" << std::endl;
        return 0.0f;
    }

    float dot_product = 0.0f;
    float norm_a = 0.0f;
    float norm_b = 0.0f;

    for (size_t i = 0; i < a.size(); ++i) {
        dot_product += a[i] * b[i];
        norm_a += a[i] * a[i];
        norm_b += b[i] * b[i];
    }

    norm_a = std::sqrt(norm_a);
    norm_b = std::sqrt(norm_b);

    if (norm_a == 0.0f || norm_b == 0.0f) {
        return 0.0f;
    }

    return dot_product / (norm_a * norm_b);
}

std::vector<float> getSentenceEmbedding(llama_mobile::llama_mobile_context& context, const std::string& sentence) {
    context.rewind();
    context.params.prompt = sentence;
    context.params.n_predict = 0; // We only want embeddings, no generation
    
    if (!context.initSampling()) {
        std::cerr << "Failed to initialize sampling for: " << sentence << std::endl;
        return {};
    }
    
    context.beginCompletion();
    context.loadPrompt();
    
    // Process the prompt to get embeddings
    context.doCompletion();
    
    common_params embd_params;
    embd_params.embd_normalize = context.params.embd_normalize;
    
    return context.getEmbedding(embd_params);
}

int main(int argc, char **argv) {
    std::cout << "\n=== Embedding Similarity Example ===" << std::endl;

    // Step 1: Determine the model path
    std::string model_path;
    
    // Option 1: User specified path
    if (argc > 1) {
        model_path = argv[1];
        std::cout << "Using user-specified model: " << model_path << std::endl;
    } 
    // Option 2: Try to find a model in the default directory
    else {
        std::string embedding_dir = "/Users/shileipeng/Documents/mygithub/llama_mobile/models/embedding";
        std::cout << "Searching for embedding models in: " << embedding_dir << std::endl;
        
        // Check if directory exists
        if (!fs::exists(embedding_dir)) {
            std::cerr << "\n❌ ERROR: Embedding directory not found: " << embedding_dir << std::endl;
            std::cerr << "Please create this directory and place GGUF embedding model files there.\n" << std::endl;
            std::cerr << "Example commands:" << std::endl;
            std::cerr << "  mkdir -p " << embedding_dir << std::endl;
            std::cerr << "  cd " << embedding_dir << std::endl;
            std::cerr << "  wget https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/blob/main/Qwen3-Embedding-0.6B-Q8_0.gguf\n" << std::endl;
            return 1;
        }
        
        // Search for any GGUF file
        bool found = false;
        for (const auto& entry : fs::directory_iterator(embedding_dir)) {
            if (entry.is_regular_file() && entry.path().extension() == ".gguf") {
                model_path = entry.path().string();
                found = true;
                break;
            }
        }
        
        if (!found) {
            std::cerr << "\n❌ ERROR: No GGUF model files found in " << embedding_dir << std::endl;
            std::cerr << "Please download at least one embedding model in GGUF format.\n" << std::endl;
            std::cerr << "Example command:" << std::endl;
            std::cerr << "  cd " << embedding_dir << std::endl;
            std::cerr << "  wget https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/blob/main/Qwen3-Embedding-0.6B-Q8_0.gguf\n" << std::endl;
            return 1;
        }
        
        std::cout << "Found model: " << model_path << std::endl;
    }

    // Step 2: Verify the model file exists
    if (!fs::exists(model_path)) {
        std::cerr << "\n❌ ERROR: Model file not found: " << model_path << std::endl;
        std::cerr << "Please check the path and try again.\n" << std::endl;
        return 1;
    }
    
    // Step 3: Try to load the model
    try {
        llama_mobile::llama_mobile_context context;

        common_params params;
        params.model.path = model_path;
        params.n_ctx = 512;
        params.n_batch = 32;
        params.n_gpu_layers = 99; 
        params.cpuparams.n_threads = 4;
        params.embedding = true;  
        params.embd_normalize = 2; 
        params.pooling_type = LLAMA_POOLING_TYPE_MEAN; 

        std::cout << "\nLoading embedding model..." << std::endl;
        if (!context.loadModel(params)) {
            std::cerr << "\n❌ ERROR: Failed to load model: " << model_path << std::endl;
            std::cerr << "Possible reasons:" << std::endl;
            std::cerr << "  1. The file is not a valid GGUF embedding model" << std::endl;
            std::cerr << "  2. The model is corrupted" << std::endl;
            std::cerr << "  3. The model is not compatible with the current implementation\n" << std::endl;
            return 1;
        }

        // Test sentences with different levels of similarity
        std::vector<std::string> sentences = {
            "The cat sits on the mat.",
            "A feline rests on the carpet.",
            "The dog runs in the park.",
            "Canines exercise in recreational areas.",
            "I love programming in Python.",
            "Machine learning is fascinating.",
            "The weather is sunny today.",
            "It's a bright and clear day outside."
        };

        std::cout << "\nGenerating embeddings for " << sentences.size() << " sentences...\n" << std::endl;

        // Generate embeddings for all sentences
        std::vector<std::vector<float>> embeddings;
        for (size_t i = 0; i < sentences.size(); ++i) {
            std::cout << "Processing sentence " << (i + 1) << "/" << sentences.size() << ": \"" 
                      << sentences[i] << "\"" << std::endl;
            
            auto embedding = getSentenceEmbedding(context, sentences[i]);
            if (embedding.empty()) {
                std::cerr << "Failed to get embedding for sentence: " << sentences[i] << std::endl;
                return 1;
            }
            embeddings.push_back(embedding);
        }

        std::cout << "\nEmbedding dimension: " << embeddings[0].size() << std::endl;

        // Calculate and display similarity matrix
        std::cout << "\n=== Cosine Similarity Matrix ===" << std::endl;
        std::cout << std::fixed << std::setprecision(3);
        
        // Header
        std::cout << std::setw(40) << " ";
        for (size_t j = 0; j < sentences.size(); ++j) {
            std::cout << std::setw(8) << "S" + std::to_string(j + 1);
        }
        std::cout << std::endl;

        // Similarity matrix
        for (size_t i = 0; i < sentences.size(); ++i) {
            // Row label (truncated sentence)
            std::string label = sentences[i];
            if (label.length() > 35) {
                label = label.substr(0, 32) + "...";
            }
            std::cout << std::setw(40) << std::left << label << std::right;
            
            for (size_t j = 0; j < sentences.size(); ++j) {
                float similarity = cosineSimilarity(embeddings[i], embeddings[j]);
                std::cout << std::setw(8) << similarity;
            }
            std::cout << std::endl;
        }

        // Find and display most similar pairs (excluding self-similarity)
        std::cout << "\n=== Most Similar Sentence Pairs ===" << std::endl;
        
        struct SimilarityPair {
            size_t i, j;
            float similarity;
        };
        
        std::vector<SimilarityPair> pairs;
        for (size_t i = 0; i < sentences.size(); ++i) {
            for (size_t j = i + 1; j < sentences.size(); ++j) {
                float sim = cosineSimilarity(embeddings[i], embeddings[j]);
                pairs.push_back({i, j, sim});
            }
        }
        
        // Sort by similarity (highest first)
        std::sort(pairs.begin(), pairs.end(), 
                  [](const SimilarityPair& a, const SimilarityPair& b) {
                      return a.similarity > b.similarity;
                  });

        // Display top 5 most similar pairs
        std::cout << "\nTop 5 most similar pairs:" << std::endl;
        for (size_t k = 0; k < std::min(size_t(5), pairs.size()); ++k) {
            const auto& pair = pairs[k];
            std::cout << std::fixed << std::setprecision(4);
            std::cout << pair.similarity << " - \"" << sentences[pair.i] 
                      << "\" <-> \"" << sentences[pair.j] << "\"" << std::endl;
        }

        // Display bottom 5 least similar pairs
        std::cout << "\nTop 5 least similar pairs:" << std::endl;
        size_t start_idx = pairs.size() >= 5 ? pairs.size() - 5 : 0;
        for (size_t k = pairs.size(); k > start_idx; --k) {
            const auto& pair = pairs[k - 1];
            std::cout << std::fixed << std::setprecision(4);
            std::cout << pair.similarity << " - \"" << sentences[pair.i] 
                      << "\" <-> \"" << sentences[pair.j] << "\"" << std::endl;
        }

        // Semantic categories
        std::cout << "\n=== Semantic Analysis ===" << std::endl;
        std::cout << "Expected similar pairs based on meaning:" << std::endl;
        std::cout << "- Animal/pet references: S1 (cat) & S2 (feline), S3 (dog) & S4 (canines)" << std::endl;
        std::cout << "- Weather descriptions: S7 (sunny) & S8 (bright day)" << std::endl;
        std::cout << "- Technology topics: S5 (Python) & S6 (ML) (somewhat related)" << std::endl;

        std::cout << "\n=== Embedding Analysis Complete ===" << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "\n❌ ERROR: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}