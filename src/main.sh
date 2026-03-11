# ============================================================================
# GITIGNORE MANAGEMENT
# ============================================================================

install_gitignore() {
    echo ""
    echo "=== Gitignore entries ==="
    append_gitignore ".agents/session-log.jsonl"
    append_gitignore ".agents/orchestrator-log.jsonl"
    append_gitignore ".agents/orchestrator.lock"
    append_gitignore ".agents/scratchpad.md"
    append_gitignore "CODE_REVIEW_*.md"
    append_gitignore "test-output.txt"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo "Yoke install.sh — profile: $PROFILE"
echo ""

# Profile containment: minimal ⊂ standard ⊂ full
install_layer2_minimal

case "$PROFILE" in
    standard|full)
        install_layer2_standard
        ;;
esac

case "$PROFILE" in
    full)
        install_layer1_full
        ;;
esac

install_gitignore

# Make shell scripts executable
find .agents/hooks -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo ""
echo "Created $CREATED files ($TEMPLATES templates with placeholders), skipped $SKIPPED existing"
echo ""
echo "Next steps:"
echo "  1. The agent will detect your toolchain and fill in {{placeholders}}"
echo "  2. The agent will generate tool-native components for your selected agent tools"
echo "  3. The agent will analyze your codebase and generate Layer 3 content"
