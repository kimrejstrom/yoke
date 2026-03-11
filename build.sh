#!/usr/bin/env bash
# build.sh - Generate install.sh from modular sources

set -euo pipefail

OUTPUT="install.sh"
SRC_DIR="src"

echo "Building $OUTPUT..."

{
    # Header
    cat "$SRC_DIR/core/header.sh"
    
    # Self-test
    cat "$SRC_DIR/core/self-test.sh"
    
    # Helpers
    cat "$SRC_DIR/core/helpers.sh"
    
    # Layers
    cat "$SRC_DIR/layers/layer2-minimal.sh"
    cat "$SRC_DIR/layers/layer2-standard.sh"
    cat "$SRC_DIR/layers/layer1-full.sh"
    
    # Main execution
    cat "$SRC_DIR/main.sh"
    
} > "$OUTPUT"

chmod +x "$OUTPUT"

# Syntax check
if bash -n "$OUTPUT"; then
    echo "✓ Generated $OUTPUT ($(wc -l < "$OUTPUT" | tr -d ' ') lines)"
    echo "✓ Syntax check passed"
else
    echo "✗ Syntax error in generated $OUTPUT"
    exit 1
fi
