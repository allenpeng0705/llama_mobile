#!/bin/bash

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== llama_mobile Tests Build & Run Script ===${NC}"

# Define paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_MOBILE_DIR="$PROJECT_ROOT/lib"
BUILD_DIR="$LLAMA_MOBILE_DIR/build"
OUTPUT_DIR="$BUILD_DIR/output"
MODELS_DIR="$PROJECT_ROOT/models"
TESTS_DIR="$OUTPUT_DIR"

# Check if build directory exists
check_build_dir() {
    if [ ! -d "$BUILD_DIR" ]; then
        echo -e "${RED}✗ Build directory not found: $BUILD_DIR${NC}"
        echo -e "${YELLOW}Please run cmake and make first to build the core library${NC}"
        exit 1
    fi
}

# Build only test executables (not core library)
build_tests() {
    echo -e "${BLUE}Building test executables...${NC}"
    cd "$BUILD_DIR"
    
    # Build all test executables
    make test_api test_advanced_chat test_chat_template test_streaming test_download direct_test chat_example test_conversation
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test executables built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build test executables${NC}"
        exit 1
    fi
}

# List available models
list_models() {
    echo -e "${BLUE}Available models:${NC}"
    
    # List .gguf files
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

# Select model
select_model() {
    if ! list_models; then
        SELECTED_MODEL=""
        return 0
    fi
    
    read -p "Enter model number (or press Enter to skip): " MODEL_SELECTION
    
    # Allow skipping model selection
    if [ -z "$MODEL_SELECTION" ]; then
        SELECTED_MODEL=""
        echo -e "${YELLOW}⚠ Skipping model selection${NC}"
        echo
        return 0
    fi
    
    # Validate selection
    if ! [[ "$MODEL_SELECTION" =~ ^[0-9]+$ ]] || [ "$MODEL_SELECTION" -lt 1 ] || [ "$MODEL_SELECTION" -gt ${#MODELS[@]} ]; then
        echo -e "${RED}✗ Invalid selection${NC}"
        exit 1
    fi
    
    SELECTED_MODEL="${MODELS[$MODEL_SELECTION-1]}"
    MODEL_NAME=$(basename "$SELECTED_MODEL")
    echo -e "${GREEN}✓ Selected model: $MODEL_NAME${NC}"
    echo
}

# Select program to run
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
        1)
            PROGRAM="test_api"
            echo -e "${GREEN}✓ Selected: test_api${NC}"
            ;;
        2)
            PROGRAM="test_advanced_chat"
            echo -e "${GREEN}✓ Selected: test_advanced_chat${NC}"
            ;;
        3)
            PROGRAM="test_chat_template"
            echo -e "${GREEN}✓ Selected: test_chat_template${NC}"
            ;;
        4)
            PROGRAM="test_streaming"
            echo -e "${GREEN}✓ Selected: test_streaming${NC}"
            ;;
        5)
            PROGRAM="test_download"
            echo -e "${GREEN}✓ Selected: test_download${NC}"
            ;;
        6)
            PROGRAM="direct_test"
            echo -e "${GREEN}✓ Selected: direct_test${NC}"
            ;;
        7)
            PROGRAM="chat_example"
            echo -e "${GREEN}✓ Selected: chat_example${NC}"
            ;;
        8)
            PROGRAM="test_conversation"
            echo -e "${GREEN}✓ Selected: test_conversation${NC}"
            ;;
        9)
            PROGRAM="all"
            echo -e "${GREEN}✓ Selected: Run all tests${NC}"
            ;;
        *)
            echo -e "${RED}✗ Invalid selection${NC}"
            exit 1
            ;;
    esac
    echo
}

# Run the selected program
run_program() {
    cd "$TESTS_DIR"
    
    if [ "$PROGRAM" = "all" ]; then
        echo -e "${BLUE}Running all tests...${NC}"
        echo -e "${YELLOW}====================================${NC}"
        
        # Run tests that don't require a model
        echo -e "\n${BLUE}1. Running test_download (interactive mode)...${NC}"
        ./"test_download"
        
        echo -e "\n${BLUE}2. Running direct_test...${NC}"
        ./"direct_test"
        
        # Run tests with model if selected
        if [ -n "$SELECTED_MODEL" ]; then
            echo -e "\n${BLUE}3. Running test_api...${NC}"
            ./"test_api" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}4. Running test_advanced_chat...${NC}"
            ./"test_advanced_chat" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}5. Running test_chat_template...${NC}"
            ./"test_chat_template" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}6. Running test_streaming...${NC}"
            ./"test_streaming" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}7. Running chat_example...${NC}"
            ./"chat_example" "$SELECTED_MODEL"
            
            echo -e "\n${BLUE}8. Running test_conversation...${NC}"
            ./"test_conversation" "$SELECTED_MODEL"
        else
            echo -e "${YELLOW}⚠ Skipping model-dependent tests (no model selected)${NC}"
            echo -e "${YELLOW}  To run all tests including model-dependent ones, select a model first${NC}"
        fi
        
        echo -e "${YELLOW}====================================${NC}"
        echo -e "${GREEN}✓ All tests completed${NC}"
    else
        echo -e "${BLUE}Running $PROGRAM...${NC}"
        echo -e "${YELLOW}====================================${NC}"
        
        if [ "$PROGRAM" = "test_download" ]; then
            # Run test_download in interactive mode
            ./"$PROGRAM"
        elif [ "$PROGRAM" = "direct_test" ]; then
            # Run direct_test without model
            ./"$PROGRAM"
        elif [ -n "$SELECTED_MODEL" ]; then
            echo -e "${BLUE}With model: $MODEL_NAME${NC}"
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

# Show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo -e ""
    echo -e "Options:"
    echo -e "  --build-only    Only build test executables, don't run"
    echo -e "  --run-only      Only run tests, don't build"
    echo -e "  --help, -h      Show this help message"
    echo -e ""
    echo -e "If no options specified, the script will build and then run tests interactively."
}

# Main execution flow
BUILD_ONLY=false
RUN_ONLY=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --build-only)
            BUILD_ONLY=true
            ;;
        --run-only)
            RUN_ONLY=true
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}✗ Unknown option: $arg${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Check build directory
check_build_dir

# Build tests if needed
if [ "$RUN_ONLY" = false ]; then
    build_tests
fi

# Run tests if needed
if [ "$BUILD_ONLY" = false ]; then
    select_program
    # Only select model if the program needs it
    if [ "$PROGRAM" != "test_download" ] && [ "$PROGRAM" != "direct_test" ]; then
        select_model
    else
        # For test_download and direct_test, skip model selection
        SELECTED_MODEL=""
        echo -e "${YELLOW}⚠ Skipping model selection (not needed for $PROGRAM)${NC}"
        echo
    fi
    run_program
fi

echo -e "${BLUE}=== Tests script completed ===${NC}"
