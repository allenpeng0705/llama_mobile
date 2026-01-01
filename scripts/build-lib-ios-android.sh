#!/bin/bash

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_LIB_SCRIPT="$SCRIPT_DIR/build-lib.sh"
BUILD_IOS_SCRIPT="$SCRIPT_DIR/build-ios.sh"
BUILD_ANDROID_SCRIPT="$SCRIPT_DIR/build-android.sh"

# Function to run a build script with error handling
run_build_script() {
    local script_name="$1"
    local script_path="$2"
    local description="$3"
    local result_var="$4"  # Name of variable to store result in
    
    echo -e "\n${CYAN}=== $description ===${NC}"
    echo -e "${BLUE}Running $script_name...${NC}"
    
    if bash "$script_path" "${@:5}"; then
        echo -e "${GREEN}✓ $script_name completed successfully${NC}"
        eval "$result_var=1"
        return 0
    else
        echo -e "${RED}✗ $script_name failed${NC}"
        eval "$result_var=0"
        return 1
    fi
}

# Function to print results summary
print_summary() {
    local lib_result="$1"
    local ios_result="$2"
    local android_result="$3"
    
    local total_count=3
    local success_count=0
    
    echo -e "\n${PURPLE}=== Build Results Summary ===${NC}"
    echo -e "\n${BLUE}Build Results:${NC}"
    
    # Check each result
    if [ "$lib_result" -eq 1 ]; then
        echo -e "  ${GREEN}✓ build-lib.sh: SUCCESS${NC}"
        ((success_count++))
    else
        echo -e "  ${RED}✗ build-lib.sh: FAILED${NC}"
    fi
    
    if [ "$ios_result" -eq 1 ]; then
        echo -e "  ${GREEN}✓ build-ios.sh: SUCCESS${NC}"
        ((success_count++))
    else
        echo -e "  ${RED}✗ build-ios.sh: FAILED${NC}"
    fi
    
    if [ "$android_result" -eq 1 ]; then
        echo -e "  ${GREEN}✓ build-android.sh: SUCCESS${NC}"
        ((success_count++))
    else
        echo -e "  ${RED}✗ build-android.sh: FAILED${NC}"
    fi
    
    local failed_count=$((total_count - success_count))
    
    echo -e "\n${BLUE}Statistics:${NC}"
    echo -e "  ${CYAN}Total builds: ${NC}$total_count"
    echo -e "  ${GREEN}Successful: ${NC}$success_count"
    echo -e "  ${RED}Failed: ${NC}$failed_count"
    
    if [ $failed_count -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All builds completed successfully!${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Some builds failed. Check the output above for details.${NC}"
        return $failed_count
    fi
}

# Main execution
echo -e "${BLUE}=== llama_mobile Multi-Platform Build Script ===${NC}"
echo -e "${YELLOW}This script will build the library for desktop, iOS, and Android platforms.${NC}"

# Initialize result variables
lib_success=0
ios_success=0
android_success=0

# Run all build scripts
run_build_script "build-lib.sh" "$BUILD_LIB_SCRIPT" "Building for Desktop/Library" lib_success
run_build_script "build-ios.sh" "$BUILD_IOS_SCRIPT" "Building for iOS" ios_success
run_build_script "build-android.sh" "$BUILD_ANDROID_SCRIPT" "Building for Android" android_success

# Print summary and exit with appropriate code
print_summary $lib_success $ios_success $android_success
exit_code=$?

echo -e "\n${BLUE}=== Build Script Completed ===${NC}"
exit $exit_code
