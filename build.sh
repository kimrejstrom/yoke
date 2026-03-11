#!/usr/bin/env bash
# build.sh - Generate install.sh from modular sources

set -euo pipefail

OUTPUT="install.sh"
SRC_DIR="src"

echo "Building $OUTPUT..."

# Helper to embed templates as heredocs
embed_template() {
    local target_path="$1"
    local template_file="$2"
    
    echo "    write_template_heredoc \"$target_path\" << 'ENDOFFILE'"
    cat "$SRC_DIR/templates/$template_file"
    echo "ENDOFFILE"
    echo ""
}

{
    # Header
    cat "$SRC_DIR/core/header.sh"
    
    # Self-test
    cat "$SRC_DIR/core/self-test.sh"
    
    # Helpers
    cat "$SRC_DIR/core/helpers.sh"
    
    # Layer 2 - Minimal
    echo ""
    echo "# ============================================================================"
    echo "# LAYER 2 — MINIMAL PROFILE (all profiles get these)"
    echo "# ============================================================================"
    echo ""
    echo "install_layer2_minimal() {"
    echo "    echo \"\""
    echo "    echo \"=== Layer 2: Core agentic loop (minimal) ===\""
    echo ""
    echo "    # --- Directories ---"
    echo "    create_dir \".agents/hooks\""
    echo "    create_dir \".agents/commands\""
    echo "    create_dir \".agents/agents/code-reviewer\""
    echo "    create_dir \".agents/skills\""
    echo "    create_dir \"scripts\""
    echo "    create_dir \"docs/plans\""
    echo ""
    echo "    # --- Template: check-completion.sh ---"
    embed_template ".agents/hooks/check-completion.sh" "check-completion.sh"
    
    echo "    # --- Template: opencode-grind-loop.sh ---"
    embed_template ".agents/hooks/opencode-grind-loop.sh" "opencode-grind-loop.sh"
    
    # Add remaining minimal profile content (config.yaml, scratchpad, etc.)
    # For now, just close the function
    echo "}"
    echo ""
    
    # Main execution
    echo "# --- Main execution ---"
    echo ""
    echo "echo \"Yoke install.sh — profile: \$PROFILE\""
    echo "echo \"\""
    echo ""
    echo "install_layer2_minimal"
    echo ""
    echo "if [ \"\$PROFILE\" = \"standard\" ] || [ \"\$PROFILE\" = \"full\" ]; then"
    echo "    echo \"TODO: install_layer2_standard\""
    echo "fi"
    echo ""
    echo "if [ \"\$PROFILE\" = \"full\" ]; then"
    echo "    echo \"TODO: install_layer1_full\""
    echo "fi"
    echo ""
    echo "# --- Gitignore entries ---"
    echo "echo \"\""
    echo "echo \"=== Gitignore entries ===\""
    echo "append_gitignore \".agents/session-log.jsonl\""
    echo "append_gitignore \".agents/orchestrator-log.jsonl\""
    echo "append_gitignore \".agents/orchestrator.lock\""
    echo "append_gitignore \".agents/scratchpad.md\""
    echo "append_gitignore \"CODE_REVIEW_*.md\""
    echo "append_gitignore \"test-output.txt\""
    echo ""
    echo "# --- Summary ---"
    echo "echo \"\""
    echo "echo \"Created \$CREATED files (\$TEMPLATES templates with placeholders), skipped \$SKIPPED existing\""
    echo "echo \"\""
    echo "echo \"Next steps:\""
    echo "echo \"  1. The agent will detect your toolchain and fill in {{placeholders}}\""
    echo "echo \"  2. The agent will generate tool-native components for your selected agent tools\""
    echo "echo \"  3. The agent will analyze your codebase and generate Layer 3 content\""
    
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
