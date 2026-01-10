#!/bin/bash

# =============================================================================
# WhatsMyShare Flutter Build Script
# =============================================================================
# A production-level build script for building iOS and Android applications
# with support for debug/release modes, code formatting, and static analysis.
#
# Usage: ./scripts/build.sh [COMMAND] [OPTIONS]
#
# Author: WhatsMyShare Team
# Version: 1.0.0
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

# Script version
readonly SCRIPT_VERSION="1.0.0"

# Project paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly FLUTTER_APP_DIR="$PROJECT_ROOT/flutter_app"

# Build output directories
readonly BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_output"
readonly IOS_OUTPUT_DIR="$BUILD_OUTPUT_DIR/ios"
readonly ANDROID_OUTPUT_DIR="$BUILD_OUTPUT_DIR/android"

# Log file
readonly LOG_DIR="$PROJECT_ROOT/logs"
readonly LOG_FILE="$LOG_DIR/build_$(date +%Y%m%d_%H%M%S).log"

# Default values
DEFAULT_BUILD_MODE="release"
DEFAULT_FORMAT_ON_BUILD="false"
DEFAULT_ANALYZE_ON_BUILD="false"
DEFAULT_VERBOSE="false"
DEFAULT_CLEAN_BUILD="false"

# =============================================================================
# COLORS AND FORMATTING
# =============================================================================

# Colors for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Symbols
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly ARROW="→"
readonly INFO_MARK="ℹ"
readonly WARNING_MARK="⚠"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Flag to track if logging is initialized
LOGGING_INITIALIZED="false"

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    LOGGING_INITIALIZED="true"
    log_info "Build script started at $(date)"
    log_info "Script version: $SCRIPT_VERSION"
    log_info "Log file: $LOG_FILE"
}

# Log to file and optionally to console
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Only write to log file if logging is initialized
    if [[ "$LOGGING_INITIALIZED" == "true" ]] && [[ -f "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

log_info() {
    log "INFO" "$1"
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}${INFO_MARK}${NC} $1"
    fi
}

log_success() {
    log "SUCCESS" "$1"
    echo -e "${GREEN}${CHECK_MARK}${NC} $1"
}

log_warning() {
    log "WARNING" "$1"
    echo -e "${YELLOW}${WARNING_MARK}${NC} $1"
}

log_error() {
    log "ERROR" "$1"
    echo -e "${RED}${CROSS_MARK}${NC} $1" >&2
}

log_step() {
    log "STEP" "$1"
    echo -e "${CYAN}${ARROW}${NC} $1"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print script header
print_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}         ${WHITE}WhatsMyShare Flutter Build Script${NC}                  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}                   ${CYAN}Version $SCRIPT_VERSION${NC}                            ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Print section header
print_section() {
    local title="$1"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  $title${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Print usage information
print_usage() {
    cat << EOF

${WHITE}USAGE:${NC}
    $(basename "$0") <COMMAND> [OPTIONS]

${WHITE}COMMANDS:${NC}
    ${GREEN}build${NC}           Build the application for specified platform(s)
    ${GREEN}format${NC}          Run dart format on all Dart files
    ${GREEN}analyze${NC}         Run dart analyze for static code analysis
    ${GREEN}clean${NC}           Clean build artifacts
    ${GREEN}doctor${NC}          Run Flutter doctor and check environment
    ${GREEN}help${NC}            Show this help message
    ${GREEN}version${NC}         Show script version

${WHITE}BUILD OPTIONS:${NC}
    ${CYAN}-p, --platform${NC}      Target platform: ios, android, or all (default: all)
    ${CYAN}-m, --mode${NC}          Build mode: debug or release (default: release)
    ${CYAN}-f, --format${NC}        Run formatter before building
    ${CYAN}-a, --analyze${NC}       Run analyzer before building
    ${CYAN}-c, --clean${NC}         Clean before building
    ${CYAN}-v, --verbose${NC}       Enable verbose output
    ${CYAN}--build-name${NC}        Set build name/version (e.g., 1.0.0)
    ${CYAN}--build-number${NC}      Set build number (e.g., 1)
    ${CYAN}--flavor${NC}            Set build flavor (e.g., dev, staging, prod)
    ${CYAN}--target${NC}            Set entry point file (default: lib/main.dart)
    ${CYAN}--obfuscate${NC}         Enable code obfuscation (release only)
    ${CYAN}--split-debug-info${NC}  Path to store split debug info
    ${CYAN}--no-tree-shake-icons${NC}  Disable icon tree shaking
    ${CYAN}--export-options-plist${NC} Path to iOS export options plist (iOS release only)

${WHITE}FORMAT OPTIONS:${NC}
    ${CYAN}--line-length${NC}       Set line length for formatter (default: 80)
    ${CYAN}--set-exit-if-changed${NC}  Exit with error if files need formatting

${WHITE}ANALYZE OPTIONS:${NC}
    ${CYAN}--fatal-infos${NC}       Treat info level issues as fatal
    ${CYAN}--fatal-warnings${NC}    Treat warning level issues as fatal

${WHITE}EXAMPLES:${NC}
    # Build release APK and iOS app
    $(basename "$0") build --platform all --mode release

    # Build debug APK with formatting
    $(basename "$0") build --platform android --mode debug --format

    # Build release iOS with code obfuscation
    $(basename "$0") build -p ios -m release --obfuscate --split-debug-info=./debug-info

    # Run formatter only
    $(basename "$0") format

    # Run analyzer only
    $(basename "$0") analyze --fatal-warnings

    # Clean and build
    $(basename "$0") build --clean --platform android --mode release

EOF
}

# Print version
print_version() {
    echo "WhatsMyShare Build Script v$SCRIPT_VERSION"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check required dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    local missing_deps=()
    
    # Check Flutter
    if command_exists flutter; then
        local flutter_version=$(flutter --version --machine 2>/dev/null | grep -o '"frameworkVersion":"[^"]*"' | cut -d'"' -f4)
        log_success "Flutter: ${flutter_version:-installed}"
    else
        missing_deps+=("flutter")
        log_error "Flutter: Not found"
    fi
    
    # Check Dart
    if command_exists dart; then
        local dart_version=$(dart --version 2>&1 | grep -o 'Dart SDK version: [0-9.]*' | cut -d' ' -f4)
        log_success "Dart: ${dart_version:-installed}"
    else
        missing_deps+=("dart")
        log_error "Dart: Not found"
    fi
    
    # Check for iOS build tools (on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists xcodebuild; then
            local xcode_version=$(xcodebuild -version 2>/dev/null | head -n1)
            log_success "Xcode: $xcode_version"
        else
            log_warning "Xcode: Not found (required for iOS builds)"
        fi
        
        if command_exists pod; then
            local pod_version=$(pod --version 2>/dev/null)
            log_success "CocoaPods: $pod_version"
        else
            log_warning "CocoaPods: Not found (required for iOS builds)"
        fi
    fi
    
    # Check for Android build tools
    if [[ -n "$ANDROID_HOME" ]] || [[ -n "$ANDROID_SDK_ROOT" ]]; then
        log_success "Android SDK: Found"
    else
        log_warning "Android SDK: ANDROID_HOME/ANDROID_SDK_ROOT not set"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "All required dependencies are available"
}

# Validate Flutter project
validate_project() {
    print_section "Validating Project"
    
    if [[ ! -d "$FLUTTER_APP_DIR" ]]; then
        log_error "Flutter app directory not found: $FLUTTER_APP_DIR"
        exit 1
    fi
    
    if [[ ! -f "$FLUTTER_APP_DIR/pubspec.yaml" ]]; then
        log_error "pubspec.yaml not found in $FLUTTER_APP_DIR"
        exit 1
    fi
    
    log_success "Project structure validated"
    
    # Get dependencies
    log_step "Getting Flutter dependencies..."
    cd "$FLUTTER_APP_DIR"
    
    if flutter pub get >> "$LOG_FILE" 2>&1; then
        log_success "Dependencies fetched successfully"
    else
        log_error "Failed to fetch dependencies"
        exit 1
    fi
}

# Create output directories
setup_output_dirs() {
    mkdir -p "$BUILD_OUTPUT_DIR"
    mkdir -p "$IOS_OUTPUT_DIR"
    mkdir -p "$ANDROID_OUTPUT_DIR"
    log_info "Output directories created"
}

# Get project version from pubspec.yaml
get_project_version() {
    local version=$(grep "^version:" "$FLUTTER_APP_DIR/pubspec.yaml" | cut -d' ' -f2)
    echo "$version"
}

# =============================================================================
# BUILD FUNCTIONS
# =============================================================================

# Run Flutter clean
run_clean() {
    print_section "Cleaning Build Artifacts"
    
    cd "$FLUTTER_APP_DIR"
    
    log_step "Running flutter clean..."
    if flutter clean >> "$LOG_FILE" 2>&1; then
        log_success "Flutter clean completed"
    else
        log_warning "Flutter clean had some issues (continuing...)"
    fi
    
    # Clean iOS pods if on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "$FLUTTER_APP_DIR/ios" ]]; then
        log_step "Cleaning iOS pods..."
        cd "$FLUTTER_APP_DIR/ios"
        rm -rf Pods Podfile.lock 2>/dev/null || true
        cd "$FLUTTER_APP_DIR"
        log_success "iOS pods cleaned"
    fi
    
    # Clean build output directory
    if [[ -d "$BUILD_OUTPUT_DIR" ]]; then
        log_step "Cleaning build output directory..."
        rm -rf "$BUILD_OUTPUT_DIR"
        log_success "Build output directory cleaned"
    fi
    
    log_success "Clean completed"
}

# Run dart format
run_format() {
    print_section "Running Code Formatter"
    
    cd "$FLUTTER_APP_DIR"
    
    local format_args=("--line-length=${LINE_LENGTH:-80}")
    
    if [[ "$SET_EXIT_IF_CHANGED" == "true" ]]; then
        format_args+=("--set-exit-if-changed")
    fi
    
    log_step "Formatting Dart files..."
    log_info "Format options: ${format_args[*]}"
    
    # Get list of dart files to format
    local dart_files=$(find lib test -name "*.dart" 2>/dev/null || true)
    
    if [[ -z "$dart_files" ]]; then
        log_warning "No Dart files found to format"
        return 0
    fi
    
    local file_count=$(echo "$dart_files" | wc -l | tr -d ' ')
    log_step "Found $file_count Dart files to check..."
    
    if dart format "${format_args[@]}" lib test >> "$LOG_FILE" 2>&1; then
        log_success "Code formatting completed"
    else
        if [[ "$SET_EXIT_IF_CHANGED" == "true" ]]; then
            log_error "Code formatting failed - some files need formatting"
            log_info "Run './scripts/build.sh format' to format files"
            exit 1
        else
            log_warning "Some formatting issues detected"
        fi
    fi
}

# Run dart analyze
run_analyze() {
    print_section "Running Static Analysis"
    
    cd "$FLUTTER_APP_DIR"
    
    local analyze_args=()
    
    if [[ "$FATAL_INFOS" == "true" ]]; then
        analyze_args+=("--fatal-infos")
    fi
    
    if [[ "$FATAL_WARNINGS" == "true" ]]; then
        analyze_args+=("--fatal-warnings")
    fi
    
    log_step "Analyzing Dart code..."
    log_info "Analyze options: ${analyze_args[*]:-none}"
    
    if flutter analyze "${analyze_args[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Static analysis completed - no issues found"
    else
        local exit_code=${PIPESTATUS[0]}
        if [[ $exit_code -ne 0 ]]; then
            log_error "Static analysis found issues"
            if [[ "$FATAL_WARNINGS" == "true" ]] || [[ "$FATAL_INFOS" == "true" ]]; then
                exit 1
            fi
        fi
    fi
}

# Build for Android
build_android() {
    print_section "Building for Android"
    
    cd "$FLUTTER_APP_DIR"
    
    local build_type="apk"
    local build_cmd="flutter build $build_type"
    local build_args=()
    
    # Add build mode
    if [[ "$BUILD_MODE" == "debug" ]]; then
        build_args+=("--debug")
    else
        build_args+=("--release")
    fi
    
    # Add build name and number if specified
    if [[ -n "$BUILD_NAME" ]]; then
        build_args+=("--build-name=$BUILD_NAME")
    fi
    
    if [[ -n "$BUILD_NUMBER" ]]; then
        build_args+=("--build-number=$BUILD_NUMBER")
    fi
    
    # Add flavor if specified
    if [[ -n "$BUILD_FLAVOR" ]]; then
        build_args+=("--flavor=$BUILD_FLAVOR")
    fi
    
    # Add target if specified
    if [[ -n "$BUILD_TARGET" ]]; then
        build_args+=("--target=$BUILD_TARGET")
    fi
    
    # Add obfuscation for release builds
    if [[ "$BUILD_MODE" == "release" ]] && [[ "$OBFUSCATE" == "true" ]]; then
        build_args+=("--obfuscate")
        if [[ -n "$SPLIT_DEBUG_INFO" ]]; then
            build_args+=("--split-debug-info=$SPLIT_DEBUG_INFO")
        else
            build_args+=("--split-debug-info=$ANDROID_OUTPUT_DIR/debug-info")
        fi
    fi
    
    # Add tree shake option
    if [[ "$NO_TREE_SHAKE_ICONS" == "true" ]]; then
        build_args+=("--no-tree-shake-icons")
    fi
    
    log_step "Building Android APK ($BUILD_MODE mode)..."
    log_info "Build command: $build_cmd ${build_args[*]}"
    
    local start_time=$(date +%s)
    
    # Use a temporary file to capture exit status since we're using pipe
    set +e
    $build_cmd "${build_args[@]}" 2>&1 | tee -a "$LOG_FILE"
    local build_exit_code=${PIPESTATUS[0]}
    set -e
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $build_exit_code -ne 0 ]]; then
        log_error "Android build failed with exit code $build_exit_code"
        log_error "Build time: ${duration}s"
        exit 1
    fi
    
    # Copy APK to output directory
    local apk_path=""
    if [[ "$BUILD_MODE" == "debug" ]]; then
        apk_path="$FLUTTER_APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
    else
        apk_path="$FLUTTER_APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
    fi
    
    if [[ -f "$apk_path" ]]; then
        setup_output_dirs
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local output_name="whats_my_share_${BUILD_MODE}_${timestamp}.apk"
        cp "$apk_path" "$ANDROID_OUTPUT_DIR/$output_name"
        
        local apk_size=$(du -h "$ANDROID_OUTPUT_DIR/$output_name" | cut -f1)
        
        log_success "Android APK built successfully"
        log_success "Output: $ANDROID_OUTPUT_DIR/$output_name"
        log_success "Size: $apk_size"
        log_success "Build time: ${duration}s"
    else
        log_error "APK file not found at expected location"
        log_error "Check: $apk_path"
        exit 1
    fi
    
    # Also build App Bundle for release
    if [[ "$BUILD_MODE" == "release" ]]; then
        log_step "Building Android App Bundle..."
        
        local aab_args=("${build_args[@]}")
        
        if flutter build appbundle "${aab_args[@]}" 2>&1 | tee -a "$LOG_FILE"; then
            local aab_path="$FLUTTER_APP_DIR/build/app/outputs/bundle/release/app-release.aab"
            
            if [[ -f "$aab_path" ]]; then
                local timestamp=$(date +%Y%m%d_%H%M%S)
                local output_name="whats_my_share_release_${timestamp}.aab"
                cp "$aab_path" "$ANDROID_OUTPUT_DIR/$output_name"
                
                local aab_size=$(du -h "$ANDROID_OUTPUT_DIR/$output_name" | cut -f1)
                
                log_success "Android App Bundle built successfully"
                log_success "Output: $ANDROID_OUTPUT_DIR/$output_name"
                log_success "Size: $aab_size"
            fi
        else
            log_warning "App Bundle build had issues (APK was built successfully)"
        fi
    fi
}

# Build for iOS
build_ios() {
    print_section "Building for iOS"
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS builds are only supported on macOS"
        exit 1
    fi
    
    # Check for Xcode
    if ! command_exists xcodebuild; then
        log_error "Xcode is required for iOS builds"
        exit 1
    fi
    
    cd "$FLUTTER_APP_DIR"
    
    # Install pods
    log_step "Installing CocoaPods dependencies..."
    cd "$FLUTTER_APP_DIR/ios"
    
    if command_exists pod; then
        if pod install >> "$LOG_FILE" 2>&1; then
            log_success "CocoaPods dependencies installed"
        else
            log_warning "CocoaPods install had issues (continuing...)"
        fi
    else
        log_warning "CocoaPods not found, skipping pod install"
    fi
    
    cd "$FLUTTER_APP_DIR"
    
    local build_args=()
    
    # Add build mode
    if [[ "$BUILD_MODE" == "debug" ]]; then
        build_args+=("--debug")
    else
        build_args+=("--release")
    fi
    
    # Add build name and number if specified
    if [[ -n "$BUILD_NAME" ]]; then
        build_args+=("--build-name=$BUILD_NAME")
    fi
    
    if [[ -n "$BUILD_NUMBER" ]]; then
        build_args+=("--build-number=$BUILD_NUMBER")
    fi
    
    # Add flavor if specified
    if [[ -n "$BUILD_FLAVOR" ]]; then
        build_args+=("--flavor=$BUILD_FLAVOR")
    fi
    
    # Add target if specified
    if [[ -n "$BUILD_TARGET" ]]; then
        build_args+=("--target=$BUILD_TARGET")
    fi
    
    # Add obfuscation for release builds
    if [[ "$BUILD_MODE" == "release" ]] && [[ "$OBFUSCATE" == "true" ]]; then
        build_args+=("--obfuscate")
        if [[ -n "$SPLIT_DEBUG_INFO" ]]; then
            build_args+=("--split-debug-info=$SPLIT_DEBUG_INFO")
        else
            build_args+=("--split-debug-info=$IOS_OUTPUT_DIR/debug-info")
        fi
    fi
    
    # Add tree shake option
    if [[ "$NO_TREE_SHAKE_ICONS" == "true" ]]; then
        build_args+=("--no-tree-shake-icons")
    fi
    
    log_step "Building iOS app ($BUILD_MODE mode)..."
    log_info "Build command: flutter build ios ${build_args[*]}"
    
    local start_time=$(date +%s)
    
    # For debug, just build the iOS app
    # For release, we need to handle signing and archiving
    if [[ "$BUILD_MODE" == "debug" ]]; then
        if flutter build ios "${build_args[@]}" --simulator 2>&1 | tee -a "$LOG_FILE"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            log_success "iOS debug build completed"
            log_success "Build time: ${duration}s"
            log_info "Run on simulator using: flutter run -d <simulator_id>"
        else
            log_error "iOS debug build failed"
            exit 1
        fi
    else
        # Release build
        if flutter build ios "${build_args[@]}" --no-codesign 2>&1 | tee -a "$LOG_FILE"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            log_success "iOS release build completed (unsigned)"
            log_success "Build time: ${duration}s"
            
            # Check if export options plist is provided for IPA export
            if [[ -n "$EXPORT_OPTIONS_PLIST" ]] && [[ -f "$EXPORT_OPTIONS_PLIST" ]]; then
                log_step "Exporting IPA..."
                
                local archive_path="$IOS_OUTPUT_DIR/Runner.xcarchive"
                
                # Archive
                cd "$FLUTTER_APP_DIR/ios"
                if xcodebuild -workspace Runner.xcworkspace \
                    -scheme Runner \
                    -configuration Release \
                    -archivePath "$archive_path" \
                    archive >> "$LOG_FILE" 2>&1; then
                    
                    log_success "Archive created successfully"
                    
                    # Export IPA
                    if xcodebuild -exportArchive \
                        -archivePath "$archive_path" \
                        -exportPath "$IOS_OUTPUT_DIR" \
                        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" >> "$LOG_FILE" 2>&1; then
                        
                        log_success "IPA exported successfully"
                        log_success "Output: $IOS_OUTPUT_DIR"
                    else
                        log_warning "IPA export failed - archive is available"
                    fi
                else
                    log_warning "Archive creation failed"
                fi
                cd "$FLUTTER_APP_DIR"
            else
                log_info "To create an IPA, provide --export-options-plist"
                log_info "Build artifacts available at: $FLUTTER_APP_DIR/build/ios/iphoneos"
            fi
        else
            log_error "iOS release build failed"
            exit 1
        fi
    fi
}

# Main build function
run_build() {
    print_section "Starting Build Process"
    
    local project_version=$(get_project_version)
    log_info "Project version: $project_version"
    log_info "Platform: $PLATFORM"
    log_info "Build mode: $BUILD_MODE"
    
    # Run format if requested
    if [[ "$FORMAT_ON_BUILD" == "true" ]]; then
        run_format
    fi
    
    # Run analyze if requested
    if [[ "$ANALYZE_ON_BUILD" == "true" ]]; then
        run_analyze
    fi
    
    # Run clean if requested
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        run_clean
        # Re-fetch dependencies after clean
        validate_project
    fi
    
    # Build for specified platform(s)
    case "$PLATFORM" in
        android)
            build_android
            ;;
        ios)
            build_ios
            ;;
        all)
            build_android
            build_ios
            ;;
        *)
            log_error "Unknown platform: $PLATFORM"
            exit 1
            ;;
    esac
    
    print_section "Build Summary"
    log_success "Build completed successfully!"
    log_info "Output directory: $BUILD_OUTPUT_DIR"
    log_info "Log file: $LOG_FILE"
}

# Run Flutter doctor
run_doctor() {
    print_section "Flutter Doctor"
    
    cd "$FLUTTER_APP_DIR"
    flutter doctor -v
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

# Initialize variables with defaults
COMMAND=""
PLATFORM="all"
BUILD_MODE="$DEFAULT_BUILD_MODE"
FORMAT_ON_BUILD="$DEFAULT_FORMAT_ON_BUILD"
ANALYZE_ON_BUILD="$DEFAULT_ANALYZE_ON_BUILD"
VERBOSE="$DEFAULT_VERBOSE"
CLEAN_BUILD="$DEFAULT_CLEAN_BUILD"
BUILD_NAME=""
BUILD_NUMBER=""
BUILD_FLAVOR=""
BUILD_TARGET=""
OBFUSCATE="false"
SPLIT_DEBUG_INFO=""
NO_TREE_SHAKE_ICONS="false"
EXPORT_OPTIONS_PLIST=""
LINE_LENGTH="80"
SET_EXIT_IF_CHANGED="false"
FATAL_INFOS="false"
FATAL_WARNINGS="false"

# Parse command - check if first argument is an option (starts with -)
if [[ $# -gt 0 ]]; then
    if [[ "$1" == -* ]]; then
        # First argument is an option, not a command
        echo -e "${RED}${CROSS_MARK}${NC} Error: No command specified" >&2
        echo ""
        echo "You must specify a command before options."
        echo "Example: ./scripts/build.sh build --platform android --mode debug"
        echo ""
        echo "Available commands: build, format, analyze, clean, doctor, help, version"
        echo "Run './scripts/build.sh help' for more information."
        exit 1
    fi
    COMMAND="$1"
    shift
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -m|--mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT_ON_BUILD="true"
            shift
            ;;
        -a|--analyze)
            ANALYZE_ON_BUILD="true"
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        --build-name)
            BUILD_NAME="$2"
            shift 2
            ;;
        --build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        --flavor)
            BUILD_FLAVOR="$2"
            shift 2
            ;;
        --target)
            BUILD_TARGET="$2"
            shift 2
            ;;
        --obfuscate)
            OBFUSCATE="true"
            shift
            ;;
        --split-debug-info)
            SPLIT_DEBUG_INFO="$2"
            shift 2
            ;;
        --no-tree-shake-icons)
            NO_TREE_SHAKE_ICONS="true"
            shift
            ;;
        --export-options-plist)
            EXPORT_OPTIONS_PLIST="$2"
            shift 2
            ;;
        --line-length)
            LINE_LENGTH="$2"
            shift 2
            ;;
        --set-exit-if-changed)
            SET_EXIT_IF_CHANGED="true"
            shift
            ;;
        --fatal-infos)
            FATAL_INFOS="true"
            shift
            ;;
        --fatal-warnings)
            FATAL_WARNINGS="true"
            shift
            ;;
        -h|--help)
            print_header
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate build mode
if [[ "$BUILD_MODE" != "debug" ]] && [[ "$BUILD_MODE" != "release" ]]; then
    log_error "Invalid build mode: $BUILD_MODE (must be 'debug' or 'release')"
    exit 1
fi

# Validate platform
if [[ "$PLATFORM" != "ios" ]] && [[ "$PLATFORM" != "android" ]] && [[ "$PLATFORM" != "all" ]]; then
    log_error "Invalid platform: $PLATFORM (must be 'ios', 'android', or 'all')"
    exit 1
fi

# Execute command
case "$COMMAND" in
    build)
        print_header
        init_logging
        check_dependencies
        validate_project
        run_build
        ;;
    format)
        print_header
        init_logging
        run_format
        ;;
    analyze)
        print_header
        init_logging
        run_analyze
        ;;
    clean)
        print_header
        init_logging
        run_clean
        ;;
    doctor)
        print_header
        run_doctor
        ;;
    version)
        print_version
        ;;
    help|--help|-h)
        print_header
        print_usage
        ;;
    "")
        print_header
        print_usage
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        print_usage
        exit 1
        ;;
esac

exit 0