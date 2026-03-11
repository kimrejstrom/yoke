#!/usr/bin/env bash
# install.sh — Yoke mechanical scaffolding (invoked by agent via YOKE_SPEC.md)
# GENERATED FILE - Edit src/ and run build.sh
#
# Usage: bash install.sh --profile minimal|standard|full [--self-test]
#
# Creates the directory structure and writes template/static files for the
# agentic development harness. Existing files are NEVER overwritten.
#
# Profiles:
#   minimal  — Layer 2 only (grind loop, completion checker, plan-first, scratchpad, config)
#   standard — Layer 2 + Layer 3 (adds AGENTS.md, docs, commands, code reviewer, CI)
#   full     — Layer 1 + Layer 2 + Layer 3 (adds orchestrator, worktree scripts, issue templates)

set -euo pipefail

# --- Argument parsing ---

PROFILE="standard"
SELF_TEST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            PROFILE="${2:-}"
            shift 2
            ;;
        --self-test)
            SELF_TEST=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: bash install.sh --profile minimal|standard|full [--self-test]"
            exit 1
            ;;
    esac
done

case "$PROFILE" in
    minimal|standard|full) ;;
    *)
        echo "Unknown profile: $PROFILE. Choose from: minimal, standard, full"
        exit 1
        ;;
esac
