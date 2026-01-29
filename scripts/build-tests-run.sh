#!/bin/bash

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== llama_mobile Tests Run Script ===${NC}"

# Define paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_MOBILE_DIR="$PROJECT_ROOT/lib"
BUILD_DIR="$LLAMA_MOBILE_DIR/build"
OUTPUT_DIR="$BUILD_DIR/output"
MODELS_DIR="$PROJECT_ROOT/models"
TESTS_DIR="$OUTPUT_DIR"

# List available models
list_models() {
    echo -e "${BLUE}Available models:${NC}"
    
    # List .gguf files
    MODELS=($(find "$MODELS_DIR" -type f -name "*.gguf" | sort))
    
    if [ ${#MODELS[@]} -eq 0 ]; then
        echo -e "${RED}✗ No .gguf models found in $MODELS_DIR${NC}"
        exit 1
    fi
    
    for i in "${!MODELS[@]}"; do
        MODEL_NAME=$(basename "${MODELS[$i]}")
        echo -e "  $((i+1)). $MODEL_NAME"
    done
    
    echo
}

# Select model
select_model() {
    list_models
    
    read -p "Enter model number: " MODEL_SELECTION
    
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
    
    echo -e "${BLUE}Running $PROGRAM with model: $MODEL_NAME...${NC}"
    echo -e "${YELLOW}====================================${NC}"
    
    # Run the program with the selected model path
    if [ "$PROGRAM" = "chat_example" ] || [ "$PROGRAM" = "test_api" ] || [ "$PROGRAM" = "test_advanced_chat" ] || [ "$PROGRAM" = "test_chat_template" ] || [ "$PROGRAM" = "test_streaming" ] || [ "$PROGRAM" = "test_download" ] || [ "$PROGRAM" = "direct_test" ]; then
        # Pass the model path directly to these programs
        ./$PROGRAM "$SELECTED_MODEL"
    else
        # For other programs that might be added later
        ./$PROGRAM
    fi
    
    echo -e "${YELLOW}====================================${NC}"
    echo -e "${GREEN}✓ Program execution completed${NC}"
}

# Main execution flow
select_program
select_model
run_program

echo -e "${BLUE}=== Tests run script completed ===${NC}"
