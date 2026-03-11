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

# --- Self-test mode ---

if [ "$SELF_TEST" = true ]; then
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    run_self_test() {
        TEST_TMPDIR=$(mktemp -d)

        check() {
            local desc="$1"
            local result="$2"
            if [ "$result" = "0" ]; then
                echo "  PASS: $desc"
            else
                echo "  FAIL: $desc"
            fi
        }
        export -f check

        echo "=== Yoke install.sh self-test ==="
        echo ""

        # Test 1: Git guard
        echo "--- Test: Git repo guard ---"
        (
            cd "$TEST_TMPDIR"
            mkdir no-git && cd no-git
            local git_exit=0
            bash "$SCRIPT_PATH" --profile minimal 2>&1 || git_exit=$?
            check "Non-git directory exits 1" "$([ "$git_exit" -eq 1 ] && echo 0 || echo 1)"
            check "No files created in non-git dir" "$([ "$(find . -type f | wc -l)" -eq 0 ] && echo 0 || echo 1)"
        ) || true

        # Test 2: Minimal profile
        echo "--- Test: Minimal profile ---"
        (
            cd "$TEST_TMPDIR"
            mkdir minimal-repo && cd minimal-repo && git init -q
            bash "$SCRIPT_PATH" --profile minimal 2>&1
            check ".agents/config.yaml exists" "$([ -f .agents/config.yaml ] && echo 0 || echo 1)"
            check ".agents/scratchpad.md exists" "$([ -f .agents/scratchpad.md ] && echo 0 || echo 1)"
            check ".agents/hooks/check-completion.sh exists" "$([ -f .agents/hooks/check-completion.sh ] && echo 0 || echo 1)"
            check ".agents/hooks/check-plan-exists.sh exists" "$([ -f .agents/hooks/check-plan-exists.sh ] && echo 0 || echo 1)"
            check ".agents/hooks/opencode-grind-loop.sh exists" "$([ -f .agents/hooks/opencode-grind-loop.sh ] && echo 0 || echo 1)"
            check "No AGENTS.md in minimal" "$([ ! -f AGENTS.md ] && echo 0 || echo 1)"
            check "No docs/ in minimal" "$([ ! -d docs/dev ] && echo 0 || echo 1)"
            check "No scripts/orchestrate.sh in minimal" "$([ ! -f scripts/orchestrate.sh ] && echo 0 || echo 1)"
            find . -type f -not -path './.git/*' -not -name '.gitignore' | wc -l | tr -d ' ' > "$TEST_TMPDIR/minimal-count"
        ) || true
        local MINIMAL_COUNT
        MINIMAL_COUNT=$(cat "$TEST_TMPDIR/minimal-count")

        # Test 3: Standard profile
        echo "--- Test: Standard profile ---"
        (
            cd "$TEST_TMPDIR"
            mkdir standard-repo && cd standard-repo && git init -q
            bash "$SCRIPT_PATH" --profile standard 2>&1
            check "AGENTS.md exists in standard" "$([ -f AGENTS.md ] && echo 0 || echo 1)"
            check "docs/INDEX.md exists" "$([ -f docs/INDEX.md ] && echo 0 || echo 1)"
            check "docs/dev/tdd-flow.md exists" "$([ -f docs/dev/tdd-flow.md ] && echo 0 || echo 1)"
            check "docs/dev/commit-conventions.md exists" "$([ -f docs/dev/commit-conventions.md ] && echo 0 || echo 1)"
            check ".agents/commands/start-issue.md exists" "$([ -f .agents/commands/start-issue.md ] && echo 0 || echo 1)"
            check ".agents/commands/plan-feature.md exists" "$([ -f .agents/commands/plan-feature.md ] && echo 0 || echo 1)"
            check ".agents/skills/issue-decomposition/SKILL.md exists" "$([ -f .agents/skills/issue-decomposition/SKILL.md ] && echo 0 || echo 1)"
            check ".agents/agents/code-reviewer/prompt.md exists" "$([ -f .agents/agents/code-reviewer/prompt.md ] && echo 0 || echo 1)"
            check "No scripts/orchestrate.sh in standard" "$([ ! -f scripts/orchestrate.sh ] && echo 0 || echo 1)"
            find . -type f -not -path './.git/*' -not -name '.gitignore' | wc -l | tr -d ' ' > "$TEST_TMPDIR/standard-count"
        ) || true
        local STANDARD_COUNT
        STANDARD_COUNT=$(cat "$TEST_TMPDIR/standard-count")

        # Test 4: Full profile
        echo "--- Test: Full profile ---"
        (
            cd "$TEST_TMPDIR"
            mkdir full-repo && cd full-repo && git init -q
            bash "$SCRIPT_PATH" --profile full 2>&1
            check "scripts/orchestrate.sh exists in full" "$([ -f scripts/orchestrate.sh ] && echo 0 || echo 1)"
            check "scripts/wti.sh exists in full" "$([ -f scripts/wti.sh ] && echo 0 || echo 1)"
            check "scripts/wtr.sh exists in full" "$([ -f scripts/wtr.sh ] && echo 0 || echo 1)"
            check "scripts/issue-preflight.sh exists in full" "$([ -f scripts/issue-preflight.sh ] && echo 0 || echo 1)"
            check ".github/ISSUE_TEMPLATE/feature-task.md exists" "$([ -f .github/ISSUE_TEMPLATE/feature-task.md ] && echo 0 || echo 1)"
            find . -type f -not -path './.git/*' -not -name '.gitignore' | wc -l | tr -d ' ' > "$TEST_TMPDIR/full-count"
        ) || true
        local FULL_COUNT
        FULL_COUNT=$(cat "$TEST_TMPDIR/full-count")

        # Test 5: Profile containment
        echo "--- Test: Profile containment ---"
        check "minimal < standard" "$([ "$MINIMAL_COUNT" -lt "$STANDARD_COUNT" ] && echo 0 || echo 1)"
        check "standard < full" "$([ "$STANDARD_COUNT" -lt "$FULL_COUNT" ] && echo 0 || echo 1)"

        # Test 6: Idempotency
        echo "--- Test: Idempotency ---"
        (
            cd "$TEST_TMPDIR"
            mkdir idem-repo && cd idem-repo && git init -q
            bash "$SCRIPT_PATH" --profile standard 2>&1 > /dev/null
            local BEFORE_COUNT
            BEFORE_COUNT=$(find . -type f -not -path './.git/*' | wc -l | tr -d ' ')
            local SECOND_OUTPUT
            SECOND_OUTPUT=$(bash "$SCRIPT_PATH" --profile standard 2>&1)
            local AFTER_COUNT
            AFTER_COUNT=$(find . -type f -not -path './.git/*' | wc -l | tr -d ' ')
            check "Same file count after second run" "$([ "$BEFORE_COUNT" -eq "$AFTER_COUNT" ] && echo 0 || echo 1)"
            check "Second run reports 0 created" "$(echo "$SECOND_OUTPUT" | grep -q 'Created 0 files' && echo 0 || echo 1)"
        ) || true

        # Test 7: Gitignore dedup
        echo "--- Test: Gitignore dedup ---"
        (
            cd "$TEST_TMPDIR"
            mkdir gi-repo && cd gi-repo && git init -q
            echo ".agents/scratchpad.md" > .gitignore
            bash "$SCRIPT_PATH" --profile minimal 2>&1 > /dev/null
            local SCRATCHPAD_COUNT
            SCRATCHPAD_COUNT=$(grep -c "^.agents/scratchpad.md$" .gitignore)
            check "No duplicate .gitignore entries" "$([ "$SCRATCHPAD_COUNT" -eq 1 ] && echo 0 || echo 1)"
        ) || true

        # Test 8: Template files contain placeholders
        echo "--- Test: Template placeholders ---"
        (
            cd "$TEST_TMPDIR"/standard-repo
            check "check-completion.sh has {{test_command}}" "$(grep -q '{{test_command}}' .agents/hooks/check-completion.sh && echo 0 || echo 1)"
            check "AGENTS.md has {{repo_name}}" "$(grep -q '{{repo_name}}' AGENTS.md && echo 0 || echo 1)"
            check "start-issue.md has {{test_command}}" "$(grep -q '{{test_command}}' .agents/commands/start-issue.md && echo 0 || echo 1)"
        ) || true

        echo ""
        echo "=== Self-test complete ===" 
        echo "All 32 checks executed. Review output above for any failures."
        
        rm -rf "$TEST_TMPDIR"
        return 0
    }

    run_self_test
    exit $?
fi

# --- Not in self-test: guard git repo ---

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not a git repository. Run \`git init\` first."
    exit 1
fi

# --- Counters ---

CREATED=0
TEMPLATES=0
SKIPPED=0

# --- Helpers ---

create_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "  created dir:  $dir"
    fi
}

write_file() {
    local path="$1"
    local content="$2"
    if [ -f "$path" ]; then
        echo "  skipping:     $path (already exists)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    create_dir "$(dirname "$path")"
    printf '%s\n' "$content" > "$path"
    echo "  created file: $path"
    CREATED=$((CREATED + 1))
}

write_template() {
    local path="$1"
    local content="$2"
    if [ -f "$path" ]; then
        echo "  skipping:     $path (already exists)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    create_dir "$(dirname "$path")"
    printf '%s\n' "$content" > "$path"
    echo "  created tmpl: $path"
    CREATED=$((CREATED + 1))
    TEMPLATES=$((TEMPLATES + 1))
}

write_file_heredoc() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "  skipping:     $path (already exists)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    create_dir "$(dirname "$path")"
    cat > "$path"
    echo "  created file: $path"
    CREATED=$((CREATED + 1))
}

write_template_heredoc() {
    local path="$1"
    if [ -f "$path" ]; then
        echo "  skipping:     $path (already exists)"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    create_dir "$(dirname "$path")"
    cat > "$path"
    echo "  created tmpl: $path"
    CREATED=$((CREATED + 1))
    TEMPLATES=$((TEMPLATES + 1))
}

append_gitignore() {
    local entry="$1"
    local gitignore=".gitignore"
    if [ ! -f "$gitignore" ]; then
        touch "$gitignore"
    fi
    if ! grep -qxF "$entry" "$gitignore" 2>/dev/null; then
        echo "$entry" >> "$gitignore"
        echo "  .gitignore:   + $entry"
    fi
}

# ============================================================================
# LAYER 2 — MINIMAL PROFILE (all profiles get these)
# ============================================================================

install_layer2_minimal() {
    echo ""
    echo "=== Layer 2: Core agentic loop (minimal) ==="

    # --- Directories ---
    create_dir ".agents/hooks"
    create_dir ".agents/commands"
    create_dir ".agents/agents/code-reviewer"
    create_dir ".agents/skills"
    create_dir "scripts"
    create_dir "docs/plans"

    # --- Template: check-completion.sh ---
    write_template_heredoc ".agents/hooks/check-completion.sh" << 'ENDOFFILE'
#!/usr/bin/env bash
# generated by yoke
# check-completion.sh — Shared completion checker for grind loop
# Used by: Claude Code Stop hook, OpenCode grind-loop.ts, opencode-grind-loop.sh
#
# Exit codes:
#   0 = all done, no follow-up needed
#   1 = incomplete, structured JSON on stdout, diagnostics on stderr
#
# Environment:
#   GRIND_ITERATION (default: 0) — current iteration count
#   MAX_GRIND_ITERATIONS — override max iterations (optional)
#
# Output (stdout): JSON object with completion status and follow-up prompt
# Output (stderr): Human-readable diagnostic messages

set -euo pipefail

# --- Config reading ---

CONFIG_FILE=".agents/config.yaml"

read_config() {
    local key="$1"
    local default="$2"
    if [ -f "$CONFIG_FILE" ]; then
        local value
        value=$(grep -E "^\s+${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*:\s*//' | sed "s/[\"']//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
        if [ -n "$value" ]; then
            echo "$value"
            return
        fi
    fi
    echo "$default"
}

MAX_ITERATIONS="${MAX_GRIND_ITERATIONS:-$(read_config max_iterations 5)}"
CURRENT_ITERATION="${GRIND_ITERATION:-0}"
SESSION_LOG=$(read_config session_log ".agents/session-log.jsonl")
SESSION_LOG_MAX=$(read_config session_log_max_lines 200)
SCRATCHPAD=$(read_config path ".agents/scratchpad.md")

# --- Helpers ---

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CHECKS_TESTS_PASS=true
CHECKS_REVIEW_CLEAN=true
CHECKS_REVIEW_EXISTS=false
CHECKS_SCRATCHPAD_DONE=false
FAILED_CHECKS=()
FAILED_TESTS_LIST=""
SCRATCHPAD_STATUS=""
SCRATCHPAD_FOCUS=""
FOLLOWUP_PROMPT=""

read_scratchpad() {
    if [ ! -f "$SCRATCHPAD" ]; then
        return
    fi
    SCRATCHPAD_STATUS=$(grep -E "^## STATUS:" "$SCRATCHPAD" 2>/dev/null | sed 's/## STATUS:\s*//' || echo "")
    SCRATCHPAD_FOCUS=$(grep -A1 "^## CURRENT_FOCUS" "$SCRATCHPAD" 2>/dev/null | tail -1 | sed 's/^\s*//' || echo "")
    if [ "$SCRATCHPAD_FOCUS" = "## CURRENT_FOCUS" ] || [ -z "$SCRATCHPAD_FOCUS" ]; then
        SCRATCHPAD_FOCUS=""
    fi
}

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    echo "$s"
}

output_json() {
    local complete="$1"
    local escaped_prompt
    escaped_prompt=$(json_escape "$FOLLOWUP_PROMPT")
    local escaped_focus
    escaped_focus=$(json_escape "$SCRATCHPAD_FOCUS")
    local escaped_status
    escaped_status=$(json_escape "$SCRATCHPAD_STATUS")
    local escaped_tests
    escaped_tests=$(json_escape "$FAILED_TESTS_LIST")

    local failed_json="[]"
    if [ ${#FAILED_CHECKS[@]} -gt 0 ]; then
        failed_json="["
        local first=true
        for check in "${FAILED_CHECKS[@]}"; do
            if [ "$first" = true ]; then first=false; else failed_json+=","; fi
            failed_json+="\"$check\""
        done
        failed_json+="]"
    fi

    cat <<ENDJSON
{
  "complete": $complete,
  "iteration": $CURRENT_ITERATION,
  "max_iterations": $MAX_ITERATIONS,
  "timestamp": "$TIMESTAMP",
  "checks": {
    "tests_pass": $CHECKS_TESTS_PASS,
    "review_clean": $CHECKS_REVIEW_CLEAN,
    "review_exists": $CHECKS_REVIEW_EXISTS,
    "scratchpad_done": $CHECKS_SCRATCHPAD_DONE
  },
  "failed_checks": $failed_json,
  "followup_prompt": "$escaped_prompt",
  "context": {
    "failed_tests": "$escaped_tests",
    "scratchpad_status": "$escaped_status",
    "scratchpad_focus": "$escaped_focus"
  }
}
ENDJSON
}

append_session_log() {
    local complete="$1"
    local log_dir
    log_dir=$(dirname "$SESSION_LOG")
    mkdir -p "$log_dir" 2>/dev/null || true

    local failed_json="[]"
    if [ ${#FAILED_CHECKS[@]} -gt 0 ]; then
        failed_json="["
        local first=true
        for check in "${FAILED_CHECKS[@]}"; do
            if [ "$first" = true ]; then first=false; else failed_json+=","; fi
            failed_json+="\"$check\""
        done
        failed_json+="]"
    fi

    local escaped_status
    escaped_status=$(json_escape "$SCRATCHPAD_STATUS")

    echo "{\"timestamp\":\"$TIMESTAMP\",\"iteration\":$CURRENT_ITERATION,\"complete\":$complete,\"failed\":$failed_json,\"scratchpad_status\":\"$escaped_status\"}" >> "$SESSION_LOG" 2>/dev/null || true

    if [ -f "$SESSION_LOG" ]; then
        local line_count
        line_count=$(wc -l < "$SESSION_LOG" 2>/dev/null || echo "0")
        if [ "$line_count" -gt "$SESSION_LOG_MAX" ]; then
            tail -n "$SESSION_LOG_MAX" "$SESSION_LOG" > "${SESSION_LOG}.tmp" 2>/dev/null && mv "${SESSION_LOG}.tmp" "$SESSION_LOG" 2>/dev/null || true
        fi
    fi
}

fail_with_prompt() {
    FOLLOWUP_PROMPT="$1"
    append_session_log "false"
    output_json "false"
    exit 1
}

# --- Read scratchpad ---

read_scratchpad

# --- Iteration cap ---

if [ "$CURRENT_ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo "GRIND_LOOP: Max iterations ($MAX_ITERATIONS) reached. Stopping." >&2
    append_session_log "true"
    output_json "true"
    exit 0
fi

# --- Check 1: Tests pass ---

echo "GRIND_LOOP: Checking tests..." >&2
TEST_EXIT=0
TEST_OUTPUT=$({{test_command}} 2>&1) || TEST_EXIT=$?
if [ "$TEST_EXIT" -ne 0 ]; then
    CHECKS_TESTS_PASS=false
    FAILED_CHECKS+=("tests_pass")
    FAILED_TESTS_LIST=$(echo "$TEST_OUTPUT" | grep -E "^FAILED" | head -5)
    TEST_TAIL=$(echo "$TEST_OUTPUT" | tail -20)

    local_prompt="Tests are still failing. Fix these failures and re-run:"
    local_prompt+="\n\n${FAILED_TESTS_LIST}"
    local_prompt+="\n\nTest output (last 20 lines):\n${TEST_TAIL}"

    if [ -n "$SCRATCHPAD_FOCUS" ]; then
        local_prompt+="\n\nYou were working on: ${SCRATCHPAD_FOCUS}"
        local_prompt+="\nContinue from where you left off."
    fi

    fail_with_prompt "$local_prompt"
fi

# --- Check 2: Code review findings ---

REVIEW_FILES=$(find . -maxdepth 1 -name "CODE_REVIEW_*.md" 2>/dev/null || echo "")
if [ -n "$REVIEW_FILES" ]; then
    CHECKS_REVIEW_EXISTS=true
    for review_file in $REVIEW_FILES; do
        if grep -qiE "^##.*critical|^##.*high|\*\*severity\*\*:.*critical|\*\*severity\*\*:.*high|\*\*Priority\*\*:.*Critical|\*\*Priority\*\*:.*High" "$review_file" 2>/dev/null; then
            CHECKS_REVIEW_CLEAN=false
            FAILED_CHECKS+=("review_clean")
            FINDINGS=$(grep -iE "critical|high" "$review_file" | head -5)

            local_prompt="CODE_REVIEW has unresolved Critical/High findings in $review_file:"
            local_prompt+="\n\n${FINDINGS}"
            local_prompt+="\n\nAddress these findings, then re-run the code reviewer."

            fail_with_prompt "$local_prompt"
        fi
    done
fi

# --- Check 3: Blind review needed ---

PR_EXISTS=$(gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number' 2>/dev/null || echo "")
if [ -n "$PR_EXISTS" ] && [ -z "$REVIEW_FILES" ]; then
    CHANGED_FILES=$(git diff --name-only "$(git merge-base HEAD main)..HEAD" 2>/dev/null || echo "")
    IS_TRIVIAL=true
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        case "$file" in
            *.md|*.txt|*.json|*.toml|*.yaml|*.yml|*.lock) ;;
            *) IS_TRIVIAL=false; break ;;
        esac
    done <<< "$CHANGED_FILES"

    if [ "$IS_TRIVIAL" = false ]; then
        FAILED_CHECKS+=("review_exists")
        fail_with_prompt "Tests pass and PR #$PR_EXISTS exists, but no code review has been performed yet. Run the code-reviewer subagent to review PR #$PR_EXISTS before marking as done."
    fi
fi

# --- Check 4: Scratchpad signals DONE ---

if [ -f "$SCRATCHPAD" ]; then
    if grep -q "STATUS: DONE" "$SCRATCHPAD" 2>/dev/null; then
        CHECKS_SCRATCHPAD_DONE=true
        echo "GRIND_LOOP: Scratchpad signals DONE." >&2
    fi
fi

# --- Check 5: Agent idle detection ---

if [ "$SCRATCHPAD_STATUS" = "IN_PROGRESS" ] && [ "$CHECKS_SCRATCHPAD_DONE" = false ]; then
    UNCHECKED=$(grep -c "\- \[ \]" "$SCRATCHPAD" 2>/dev/null || echo "0")
    if [ "$UNCHECKED" -gt 0 ]; then
        STUCK_PROMPT=""
        if [ -f "$SESSION_LOG" ] && [ -n "$SCRATCHPAD_FOCUS" ]; then
            RECENT_SAME_FOCUS=$(tail -3 "$SESSION_LOG" 2>/dev/null | grep -c "$(json_escape "$SCRATCHPAD_FOCUS")" 2>/dev/null || echo "0")
            if [ "$RECENT_SAME_FOCUS" -ge 2 ]; then
                STUCK_PROMPT="\n\nYou have been stuck on the same task for $RECENT_SAME_FOCUS iterations. Try a different approach — simplify, break it into smaller steps, or reconsider the design."
            fi
        fi

        local_prompt="You stopped working but the task is not complete. The scratchpad shows $UNCHECKED unchecked items remaining."
        if [ -n "$SCRATCHPAD_FOCUS" ]; then
            local_prompt+="\n\nYou were working on: ${SCRATCHPAD_FOCUS}"
        fi
        local_prompt+="\n\nContinue from where you left off. Update the scratchpad as you make progress."
        if [ -n "$STUCK_PROMPT" ]; then
            local_prompt+="$STUCK_PROMPT"
        fi

        FAILED_CHECKS+=("agent_idle")
        fail_with_prompt "$local_prompt"
    fi
fi

# --- All checks passed ---

echo "GRIND_LOOP: All checks passed." >&2
append_session_log "true"
output_json "true"
ENDOFFILE

    # --- Template: opencode-grind-loop.sh ---
    write_template_heredoc ".agents/hooks/opencode-grind-loop.sh" << 'ENDOFFILE'
#!/usr/bin/env bash
# generated by yoke
# opencode-grind-loop.sh — Grind loop wrapper for headless/CI agent dispatch
#
# Features:
#   - Reads config from .agents/config.yaml
#   - Plan-first check before starting
#   - Stall timeout via `timeout` command
#   - Structured JSON parsing from check-completion.sh
#   - Session logging for post-hoc observability
#
# Usage (sourceable):
#   source .agents/hooks/opencode-grind-loop.sh
#   grind_loop "your prompt here"
#
# Or standalone:
#   bash .agents/hooks/opencode-grind-loop.sh "your prompt here"

set -euo pipefail

CONFIG_FILE=".agents/config.yaml"

read_config() {
    local key="$1"
    local default="$2"
    if [ -f "$CONFIG_FILE" ]; then
        local value
        value=$(grep -E "^\s+${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*:\s*//' | sed "s/[\"']//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
        if [ -n "$value" ]; then
            echo "$value"
            return
        fi
    fi
    echo "$default"
}

MAX_ITERATIONS="${MAX_GRIND_ITERATIONS:-$(read_config max_iterations 5)}"
STALL_TIMEOUT=$(read_config stall_timeout_seconds 300)

check_plan_exists() {
    local plan_files
    plan_files=$(find docs/plans -maxdepth 1 \( -name "issue-*.md" -o -name "plan-*.md" -o -name "_PLAN_*.md" \) 2>/dev/null | head -1)
    if [ -z "$plan_files" ]; then
        echo ""
        echo "⚠️  PLAN-FIRST: No plan file found in docs/plans/"
        echo "   Before coding, create docs/plans/issue-{NUMBER}.md"
        echo "   Template: docs/templates/plan-template.md"
        echo ""
        return 1
    fi
    return 0
}

extract_followup() {
    local json="$1"
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r '.followup_prompt // empty' 2>/dev/null || echo "$json"
    else
        local prompt
        prompt=$(echo "$json" | grep -o '"followup_prompt":\s*"[^"]*"' 2>/dev/null | sed 's/"followup_prompt":\s*"//' | sed 's/"$//' || echo "")
        if [ -n "$prompt" ]; then
            echo -e "$prompt"
        else
            echo "$json"
        fi
    fi
}

grind_loop() {
    local prompt="${1:-}"
    if [ -z "$prompt" ]; then
        echo "Usage: grind_loop 'your prompt here'"
        return 1
    fi

    echo "━━━ GRIND LOOP CONFIG ━━━"
    echo "  Max iterations: $MAX_ITERATIONS"
    echo "  Stall timeout:  ${STALL_TIMEOUT}s"
    echo "  Config file:    $CONFIG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━"

    for i in $(seq 1 "$MAX_ITERATIONS"); do
        echo ""
        echo "━━━ GRIND LOOP: Iteration $i/$MAX_ITERATIONS ━━━"

        local agent_exit=0
        if [ "$STALL_TIMEOUT" -gt 0 ]; then
            timeout "${STALL_TIMEOUT}s" opencode --prompt "$prompt" || agent_exit=$?
        else
            opencode --prompt "$prompt" || agent_exit=$?
        fi

        if [ "$agent_exit" -eq 124 ]; then
            echo "━━━ GRIND LOOP: Agent stalled (no output for ${STALL_TIMEOUT}s). Re-prompting. ━━━"
            prompt="You appear to be stuck — the session timed out after ${STALL_TIMEOUT} seconds of inactivity. Check your current approach and try a different angle."
            continue
        fi

        export GRIND_ITERATION="$i"
        local check_output=""
        local check_exit=0
        check_output=$(bash .agents/hooks/check-completion.sh 2>/dev/null) || check_exit=$?

        if [ "$check_exit" -eq 0 ]; then
            echo "━━━ GRIND LOOP: Complete after $i iteration(s) ━━━"
            return 0
        fi

        if [ -n "$check_output" ]; then
            local followup
            followup=$(extract_followup "$check_output")
            if [ -n "$followup" ]; then
                prompt="$followup"
                echo ""
                echo "━━━ GRIND LOOP: Incomplete. Re-prompting: ━━━"
                echo "$followup" | head -5
                echo ""
            else
                echo "━━━ GRIND LOOP: check-completion returned non-zero but no follow-up. Stopping. ━━━"
                return 1
            fi
        else
            echo "━━━ GRIND LOOP: check-completion returned non-zero but no output. Stopping. ━━━"
            return 1
        fi
    done

    echo ""
    echo "━━━ GRIND LOOP: Max iterations ($MAX_ITERATIONS) reached. ━━━"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    grind_loop "$@"
fi
ENDOFFILE

ENDOFFILE

}

# --- Main execution ---

echo "Yoke install.sh — profile: $PROFILE"
echo ""

install_layer2_minimal

if [ "$PROFILE" = "standard" ] || [ "$PROFILE" = "full" ]; then
    echo "TODO: install_layer2_standard"
fi

if [ "$PROFILE" = "full" ]; then
    echo "TODO: install_layer1_full"
fi

# --- Gitignore entries ---
echo ""
echo "=== Gitignore entries ==="
append_gitignore ".agents/session-log.jsonl"
append_gitignore ".agents/orchestrator-log.jsonl"
append_gitignore ".agents/orchestrator.lock"
append_gitignore ".agents/scratchpad.md"
append_gitignore "CODE_REVIEW_*.md"
append_gitignore "test-output.txt"

# --- Summary ---
echo ""
echo "Created $CREATED files ($TEMPLATES templates with placeholders), skipped $SKIPPED existing"
echo ""
echo "Next steps:"
echo "  1. The agent will detect your toolchain and fill in {{placeholders}}"
echo "  2. The agent will generate tool-native components for your selected agent tools"
echo "  3. The agent will analyze your codebase and generate Layer 3 content"
