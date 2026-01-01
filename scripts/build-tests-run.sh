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
MODELS_DIR="$LLAMA_MOBILE_DIR/models"
TESTS_DIR="$OUTPUT_DIR"

# List available .gguf models
list_models() {
    echo -e "${BLUE}Available models:${NC}"
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
    echo -e "  2. chat_example (Interactive chat)"
    echo
    
    read -p "Enter selection: " PROGRAM_SELECTION
    
    case "$PROGRAM_SELECTION" in
        1)
            PROGRAM="test_api"
            echo -e "${GREEN}✓ Selected: test_api${NC}"
            ;;
        2)
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
    if [ "$PROGRAM" = "chat_example" ] || [ "$PROGRAM" = "test_api" ]; then
        # Pass the model path directly to both programs now
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
