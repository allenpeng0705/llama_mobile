#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== llama_mobile Tests Build & Run Script ===${NC}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_MOBILE_DIR="$PROJECT_ROOT/lib"
BUILD_DIR="$LLAMA_MOBILE_DIR/tests/build"
MODELS_DIR="$PROJECT_ROOT/models"

build_tests() {
    echo -e "${BLUE}Building test executables...${NC}"
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    cmake -B . -DCMAKE_BUILD_TYPE=Release -S "$LLAMA_MOBILE_DIR/tests" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ CMake configuration failed${NC}"
        cmake -B . -DCMAKE_BUILD_TYPE=Release -S "$LLAMA_MOBILE_DIR/tests"
        exit 1
    fi
    
    NPROC=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    cmake --build . -j$NPROC
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test executables built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build test executables${NC}"
        exit 1
    fi
}

# Prompts the user to pick one file matching a glob under MODELS_DIR.
pick_file() {
    local pattern="$1"
    local prompt="$2"
    local -a FILES
    FILES=($(find "$MODELS_DIR" -type f -name "$pattern" 2>/dev/null | sort))
    
    if [ ${#FILES[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠ No file matching '$pattern' under $MODELS_DIR${NC}"
        return 1
    fi
    if [ ${#FILES[@]} -eq 1 ]; then
        echo "${FILES[0]}"
        return 0
    fi
    echo -e "${BLUE}$prompt${NC}"
    for i in "${!FILES[@]}"; do
        echo -e "  $((i+1)). $(basename "${FILES[$i]}")"
    done
    read -p "Enter file number: " FILE_SELECTION
    if ! [[ "$FILE_SELECTION" =~ ^[0-9]+$ ]] || [ "$FILE_SELECTION" -lt 1 ] || [ "$FILE_SELECTION" -gt ${#FILES[@]} ]; then
        echo -e "${RED}✗ Invalid selection${NC}"
        exit 1
    fi
    echo "${FILES[$FILE_SELECTION-1]}"
}

list_models() {
    echo -e "${BLUE}Available models:${NC}"
    
    MODELS=($(find "$MODELS_DIR" -type f -name "*.gguf" 2>/dev/null | sort))
    
    if [ ${#MODELS[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠ No .gguf models found in $MODELS_DIR${NC}"
        echo -e "${YELLOW}  Tests that don't require a model will still work${NC}"
        return 1
    fi
    
    for i in "${!MODELS[@]}"; do
        MODEL_NAME=$(basename "${MODELS[$i]}")
        MODEL_SIZE=$(du -h "${MODELS[$i]}" | cut -f1)
        echo -e "  $((i+1)). $MODEL_NAME ($MODEL_SIZE)"
    done
    
    echo
    return 0
}

select_model() {
    if ! list_models; then
        SELECTED_MODEL=""
        return 0
    fi
    
    read -p "Enter model number (or press Enter to skip): " MODEL_SELECTION
    
    if [ -z "$MODEL_SELECTION" ]; then
        SELECTED_MODEL=""
        echo -e "${YELLOW}⚠ Skipping model selection${NC}"
        echo
        return 0
    fi
    
    if ! [[ "$MODEL_SELECTION" =~ ^[0-9]+$ ]] || [ "$MODEL_SELECTION" -lt 1 ] || [ "$MODEL_SELECTION" -gt ${#MODELS[@]} ]; then
        echo -e "${RED}✗ Invalid selection${NC}"
        exit 1
    fi
    
    SELECTED_MODEL="${MODELS[$MODEL_SELECTION-1]}"
    MODEL_NAME=$(basename "$SELECTED_MODEL")
    echo -e "${GREEN}✓ Selected model: $MODEL_NAME${NC}"
    echo
}

select_program() {
    echo -e "${BLUE}Select program to run (v2 suites + engine-level host suites):${NC}"
    echo -e "  1. test_v2_meta (no-model meta/IDL checks)"
    echo -e "  2. test_v2_functional (model: context/generate/chat/embed)"
    echo -e "  3. test_v2_threads (model: abort/concurrency)"
    echo -e "  4. test_v2_streaming (model: token stream order + early stop)"
    echo -e "  5. test_v2_lora (model + lora adapter)"
    echo -e "  6. test_v2_multimodal (vision model + mmproj + image)"
    echo -e "  7. test_v2_tts (model + vocoder)"
    echo -e "  8. test_chat_template (engine-level template formatting)"
    echo -e "  9. direct_test (engine-level direct loader)"
    echo -e "  10. test_v2_download (no-model: download manager + model registry)"
    echo -e "  11. Auto: run all non-interactive single-model suites"
    echo
    
    read -p "Enter selection: " PROGRAM_SELECTION
    
    case "$PROGRAM_SELECTION" in
        1) PROGRAM="test_v2_meta" ;;
        2) PROGRAM="test_v2_functional" ;;
        3) PROGRAM="test_v2_threads" ;;
        4) PROGRAM="test_v2_streaming" ;;
        5) PROGRAM="test_v2_lora" ;;
        6) PROGRAM="test_v2_multimodal" ;;
        7) PROGRAM="test_v2_tts" ;;
        8) PROGRAM="test_chat_template" ;;
        9) PROGRAM="direct_test" ;;
        10) PROGRAM="test_v2_download" ;;
        11) PROGRAM="auto" ;;
        *)
            echo -e "${RED}✗ Invalid selection${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✓ Selected: $PROGRAM${NC}"
    echo
}

# Resolves the extra per-suite model assets (std fixtures preferred).
extra_assets() {
    case "$PROGRAM" in
        test_v2_lora)
            LORA_PATH="$(pick_file 'lora/*.gguf' 'Select a LoRA adapter:')" || LORA_PATH=""
            ;;
        test_v2_multimodal)
            MMPROJ_PATH="$(pick_file 'mmproj-*.gguf' 'Select an mmproj:')" || MMPROJ_PATH=""
            IMAGE_PATH="$(pick_file 'img/*' 'Select an image:')" || IMAGE_PATH=""
            ;;
        test_v2_tts)
            # speak requires the TTS main model (OuteTTS); fall back to the
            # selected main model for lifecycle-only checks.
            MAIN_TTS_PATH="$(pick_file '*OuteTTS*' 'Select the TTS main model:')" || MAIN_TTS_PATH="$SELECTED_MODEL"
            VOCODER_PATH="$(pick_file '*WavTokenizer*' 'Select a vocoder model:')" || VOCODER_PATH=""
            if [ -z "$VOCODER_PATH" ]; then
                VOCODER_PATH="$(pick_file '*neuttn*' 'Select a vocoder model:')" || VOCODER_PATH=""
    MAIN_TTS_PATH="$(pick_file '*OuteTTS*' 'Select the TTS main model:')" || MAIN_TTS_PATH="$SELECTED_MODEL"
            fi
            ;;
    esac
}

run_program() {
    cd "$BUILD_DIR"

    if [ "$PROGRAM" = "auto" ]; then
        echo -e "${BLUE}Running the non-interactive v2 suites...${NC}"
        echo -e "${YELLOW}====================================${NC}"

        echo -e "\n${BLUE}1. test_v2_meta (no model)...${NC}"
        ./test_v2_meta || { echo -e "${RED}✗ test_v2_meta failed${NC}"; exit 1; }

        echo -e "\n${BLUE}2. test_v2_download (no model)...${NC}"
        ./test_v2_download || { echo -e "${RED}✗ test_v2_download failed${NC}"; exit 1; }

        if [ -n "$SELECTED_MODEL" ]; then
            for t in test_v2_functional test_v2_threads test_v2_streaming test_chat_template direct_test; do
                echo -e "\n${BLUE}$t ${SELECTED_MODEL}...${NC}"
                ./"$t" "$SELECTED_MODEL" || { echo -e "${RED}✗ $t failed${NC}"; exit 1; }
            done
            echo -e "${YELLOW}  (test_v2_lora / test_v2_multimodal / test_v2_tts need extra assets; run them individually)${NC}"
        else
            echo -e "${YELLOW}⚠ Skipping model-dependent suites (no model selected)${NC}"
        fi

        echo -e "\n${YELLOW}====================================${NC}"
        echo -e "${GREEN}✓ All automated suites passed${NC}"
    else
        echo -e "${BLUE}Running $PROGRAM...${NC}"
        echo -e "${YELLOW}====================================${NC}"

        if [ "$PROGRAM" = "test_v2_meta" ] || [ "$PROGRAM" = "test_v2_download" ]; then
            ./"$PROGRAM"
        elif [ "$PROGRAM" = "test_v2_lora" ]; then
            if [ -z "$SELECTED_MODEL" ] || [ -z "$LORA_PATH" ]; then
                echo -e "${YELLOW}⚠ test_v2_lora requires a base model and a LoRA adapter${NC}"
                exit 1
            fi
            ./"$PROGRAM" "$SELECTED_MODEL" "$LORA_PATH"
        elif [ "$PROGRAM" = "test_v2_multimodal" ]; then
            if [ -z "$SELECTED_MODEL" ] || [ -z "$MMPROJ_PATH" ] || [ -z "$IMAGE_PATH" ]; then
                echo -e "${YELLOW}⚠ test_v2_multimodal requires a vision model, mmproj and an image${NC}"
                exit 1
            fi
            ./"$PROGRAM" "$SELECTED_MODEL" "$MMPROJ_PATH" "$IMAGE_PATH"
        elif [ "$PROGRAM" = "test_v2_tts" ]; then
            if [ -z "$SELECTED_MODEL" ] || [ -z "$VOCODER_PATH" ]; then
                echo -e "${YELLOW}⚠ test_v2_tts requires a main model and a vocoder model${NC}"
                exit 1
            fi
            ./"$PROGRAM" "$MAIN_TTS_PATH" "$VOCODER_PATH"
        elif [ -n "$SELECTED_MODEL" ]; then
            echo -e "${BLUE}With model: $(basename "$SELECTED_MODEL")${NC}"
            ./"$PROGRAM" "$SELECTED_MODEL"
        else
            echo -e "${YELLOW}⚠ No model selected${NC}"
            echo -e "${YELLOW}  This program requires a model${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}====================================${NC}"
        echo -e "${GREEN}✓ Program execution completed${NC}"
    fi
}

show_usage() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo -e ""
    echo -e "Options:"
    echo -e "  --build-only    Only build test executables, don't run"
    echo -e "  --run-only      Only run tests, don't build"
    echo -e " --help, -h      Show this help message"
    echo -e ""
    echo -e "If no options specified, the script will build and then run tests interactively."
}

BUILD_ONLY=false
RUN_ONLY=false

for arg in "$@"; do
    case $arg in
        --build-only) BUILD_ONLY=true ;;
        --run-only) RUN_ONLY=true ;;
        --help|-h) show_usage; exit 0 ;;
        *)
            echo -e "${RED}✗ Unknown option: $arg${NC}"
            show_usage
            exit 1
            ;;
    esac
done

if [ "$RUN_ONLY" = false ]; then
    build_tests
fi

if [ "$BUILD_ONLY" = false ]; then
    select_program
    if [ "$PROGRAM" != "auto" ] && [ "$PROGRAM" != "test_v2_meta" ]; then
        select_model
        extra_assets
    else
        SELECTED_MODEL=""
        LORA_PATH=""
        MMPROJ_PATH=""
        IMAGE_PATH=""
        VOCODER_PATH=""
        echo -e "${YELLOW}⚠ No model needed for $PROGRAM${NC}"
        echo
    fi
    run_program
fi

echo -e "${BLUE}=== Tests script completed ===${NC}"
