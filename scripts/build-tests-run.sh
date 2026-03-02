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
    echo -e "${BLUE}Select program to run:${NC}"
    echo -e "  1. test_api (API test program)"
    echo -e "  2. test_advanced_chat (Advanced chat features test)"
    echo -e "  3. test_chat_template (Chat template test)"
    echo -e "  4. test_streaming (Streaming test)"
    echo -e "  5. test_download (Download test)"
    echo -e "  6. direct_test (Direct API test)"
    echo -e "  7. chat_example (Interactive chat)"
    echo -e "  8. test_conversation (Conversation API test)"
    echo -e "  9. Run all tests"
    echo
    
    read -p "Enter selection: " PROGRAM_SELECTION
    
    case "$PROGRAM_SELECTION" in
        1) PROGRAM="test_api" ;;
        2) PROGRAM="test_advanced_chat" ;;
        3) PROGRAM="test_chat_template" ;;
        4) PROGRAM="test_streaming" ;;
        5) PROGRAM="test_download" ;;
        6) PROGRAM="direct_test" ;;
        7) PROGRAM="chat_example" ;;
        8) PROGRAM="test_conversation" ;;
        9) PROGRAM="all" ;;
        *)
            echo -e "${RED}✗ Invalid selection${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✓ Selected: $PROGRAM${NC}"
    echo
}

run_program() {
    cd "$BUILD_DIR"
    
    if [ "$PROGRAM" = "all" ]; then
        echo -e "${BLUE}Running all tests...${NC}"
        echo -e "${YELLOW}====================================${NC}"
        
        echo -e "\n${BLUE}1. Running test_download...${NC}"
        ./"test_download" --help
        
        if [ -n "$SELECTED_MODEL" ]; then
            echo -e "\n${BLUE}2. Running test_api...${NC}"
            ./"test_api" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}3. Running test_advanced_chat...${NC}"
            ./"test_advanced_chat" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}4. Running test_chat_template...${NC}"
            ./"test_chat_template" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}5. Running test_streaming...${NC}"
            ./"test_streaming" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}6. Running chat_example...${NC}"
            ./"chat_example" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}7. Running test_conversation...${NC}"
            ./"test_conversation" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}8. Running direct_test...${NC}"
            ./"direct_test" "$SELECTED_MODEL"
        else
            echo -e "${YELLOW}⚠ Skipping model-dependent tests (no model selected)${NC}"
        fi
        
        echo -e "${YELLOW}====================================${NC}"
        echo -e "${GREEN}✓ All tests completed${NC}"
    else
        echo -e "${BLUE}Running $PROGRAM...${NC}"
        echo -e "${YELLOW}====================================${NC}"
        
        if [ "$PROGRAM" = "test_download" ]; then
            ./"$PROGRAM"
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
    if [ "$PROGRAM" != "test_download" ]; then
        select_model
    else
        SELECTED_MODEL=""
        echo -e "${YELLOW}⚠ Skipping model selection (not needed for $PROGRAM)${NC}"
        echo
    fi
    run_program
fi

echo -e "${BLUE}=== Tests script completed ===${NC}"
