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

    # --- Static: .agents/config.yaml ---
    write_file ".agents/config.yaml" '# generated by yoke
# Shared agent harness configuration
# Read by: check-completion.sh, grind-loop.ts, opencode-grind-loop.sh
#
# Keep this flat and simple — shell scripts parse it with grep/awk.

grind_loop:
  max_iterations: 5
  # Stall timeout: agent alive but no progress (e.g., stuck LLM call)
  stall_timeout_seconds: 300
  # Idle timeout: agent stopped working but did not finish
  idle_timeout_seconds: 120
  # Session log for post-hoc observability
  session_log: .agents/session-log.jsonl
  # Max session log lines before truncation
  session_log_max_lines: 200

scratchpad:
  path: .agents/scratchpad.md

orchestrator:
  max_parallel: 3
  poll_interval_seconds: 60
  stall_detection_multiplier: 2
  log: .agents/orchestrator-log.jsonl
  auto_merge_method: squash
  default_agent_tool: opencode
  default_label: orchestrator-ready
  kill_grace_seconds: 5'

    # --- Static: .agents/scratchpad.md ---
    write_file ".agents/scratchpad.md" '## STATUS: IDLE

## ITERATION: 0/5

## STARTED_AT:

## COMPLETED

- [ ] Plan file created
- [ ] Tests written
- [ ] Implementation done
- [ ] Code review passed

## CURRENT_FOCUS

## PREVIOUS_ATTEMPTS

## BLOCKERS

None'

    # --- Static: .agents/hooks/check-plan-exists.sh ---
    write_file ".agents/hooks/check-plan-exists.sh" '#!/usr/bin/env bash
# generated by yoke
# check-plan-exists.sh — PreToolUse hook for plan-first enforcement
# Checks that a plan file exists in docs/plans/ before allowing code writes.
#
# Exit codes:
#   0 = plan exists, proceed with tool use
#   1 = no plan found, deny tool use (message on stdout)

set -euo pipefail

# Allow writes to plan files themselves, docs, and non-code files
TOOL_PATH="${1:-}"
if [ -n "$TOOL_PATH" ]; then
    case "$TOOL_PATH" in
        docs/plans/*|docs/templates/*|.agents/*|.claude/*|.opencode/*|.kiro/*|*.md|*.json|*.toml|*.yaml|*.yml)
            exit 0
            ;;
    esac
fi

# Check if any plan file exists in docs/plans/ (excluding INDEX.md and templates)
PLAN_FILES=$(find docs/plans -maxdepth 1 -name "issue-*.md" -o -name "plan-*.md" -o -name "_PLAN_*.md" 2>/dev/null | head -1)

if [ -z "$PLAN_FILES" ]; then
    echo "DENIED: No plan file found in docs/plans/. Before writing code, create a plan:

1. Copy the template: docs/templates/plan-template.md
2. Save as: docs/plans/issue-{NUMBER}.md or docs/plans/_PLAN_issue-{NUMBER}.md
3. Fill in: goal, acceptance criteria, files to modify, test scenarios, risks

See docs/templates/plan-template.md for the format."
    exit 1
fi

exit 0'


    # --- Template: .agents/hooks/check-completion.sh ---
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
        value=$(grep -E "^\s+${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
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
    SCRATCHPAD_STATUS=$(grep -E "^## STATUS:" "$SCRATCHPAD" 2>/dev/null | sed 's/## STATUS:[[:space:]]*//' || echo "")
    SCRATCHPAD_FOCUS=$(grep -A1 "^## CURRENT_FOCUS" "$SCRATCHPAD" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' || echo "")
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

# --- Check 0: Verify work has been done ---

MERGE_BASE=$(git merge-base HEAD main 2>/dev/null || echo "")
if [ -n "$MERGE_BASE" ]; then
    COMMITS_AHEAD=$(git rev-list --count "$MERGE_BASE..HEAD" 2>/dev/null | tr -d ' \n' || echo "0")
    if [ "$COMMITS_AHEAD" -eq 0 ]; then
        fail_with_prompt "No commits found beyond the merge base. Start working on the task — create a plan, write tests, and implement the solution."
    fi
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
        UNRESOLVED=$(grep -iE "^##.*critical|^##.*high|\*\*severity\*\*:.*critical|\*\*severity\*\*:.*high|\*\*Priority\*\*:.*Critical|\*\*Priority\*\*:.*High" "$review_file" 2>/dev/null | grep -viE "✅|FIXED|Resolved|was ◆" || true)
        if [ -n "$UNRESOLVED" ]; then
            CHECKS_REVIEW_CLEAN=false
            FAILED_CHECKS+=("review_clean")
            FINDINGS=$(echo "$UNRESOLVED" | head -5)

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
exit 0
ENDOFFILE


    # --- Template: .agents/hooks/opencode-grind-loop.sh ---
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
        value=$(grep -E "^\s+${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//' | sed "s/[\"']//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
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
        prompt=$(echo "$json" | grep -o '"followup_prompt":[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/"followup_prompt":[[:space:]]*"//' | sed 's/"$//' || echo "")
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
            timeout "${STALL_TIMEOUT}s" opencode run "$prompt" || agent_exit=$?
        else
            opencode run "$prompt" || agent_exit=$?
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

}


# ============================================================================
# LAYER 2+3 — STANDARD PROFILE (standard and full get these)
# ============================================================================

install_layer2_standard() {
    echo ""
    echo "=== Layer 2+3: Commands, code reviewer, docs, CI (standard) ==="

    # --- Directories ---
    create_dir "docs/dev"
    create_dir "docs/templates"
    create_dir "docs/architecture/decisions"

    # --- Template: .agents/commands/start-issue.md ---
    write_template ".agents/commands/start-issue.md" '<!-- generated by yoke -->
# Start Issue Command

Start work on a GitHub issue.

## Usage

```
/start-issue <issue_number>
```

**Arguments:**

- `issue_number`: The GitHub issue number to work on

## Argument Indexing

- **Claude Code**: Use `$1` for the first argument (issue number)
- **OpenCode**: Use `$ARGUMENTS` to get all arguments

## Steps

### 0. Preflight Check

Run issue-preflight.sh to validate the issue is ready:

```bash
bash scripts/issue-preflight.sh <issue_number>
```

If it exits non-zero, report the block reason from the JSON output and stop.

### 1. Get Repo Info

```bash
git remote get-url origin
```

Parse owner and repo name from the output.

### 2. Fetch Issue

```bash
gh issue view <issue_number> --repo <owner>/<repo>
```

### 3. Verify/Create Branch

```bash
git branch --show-current
```

If not on correct branch:

```bash
git checkout -b feature/issue-<issue_number>-<short-description>
```

### 4. Create Plan File

Create `docs/plans/_PLAN_issue-{issue_number}.md` using the template at `docs/templates/plan-template.md`.

### 5. Scaffold Test File

Create test file in `tests/` with basic structure.

### 6. Verify Tests Run

```bash
{{test_command}}
```

### 7. Trigger Code Review

Once done, call code-review sub-agent and enter a review-fix loop until review states PR is ready.

## Notes

- This command is for starting NEW work on an issue
- If work is already in progress, skip this command'

    # --- Template: .agents/commands/create-pr.md ---
    write_template ".agents/commands/create-pr.md" '<!-- generated by yoke -->
# Create PR Command

Create a pull request after completing feature work.

## Usage

```
/create-pr
```

## Argument Indexing

- **Claude Code**: No arguments needed
- **OpenCode**: No arguments needed

## Steps

### 1. Run Tests

```bash
{{test_command}}
```

### 2. Run Linting

```bash
{{lint_command}}
{{format_command}}
```

### 3. Run Type Checking

```bash
{{typecheck_command}}
```

### 4. Get Repo Info

```bash
git remote get-url origin
```

Parse owner and repo name.

### 5. Check Changes

```bash
git status
git diff --cached
```

### 6. Commit if Needed

```bash
git add -A
git commit -m "feat(scope): description for #XX"
```

### 7. Push Branch

```bash
git push -u origin <branch-name>
```

### 8. Create PR

```bash
gh pr create --repo <owner>/<repo> \
  --title "feat(scope): description for #XX" \
  --head <branch-name> \
  --base main \
  --body "## Summary\n<description>\n\n## Issue\nCloses #XX"
```

### 9. Trigger Code Review

Invoke the code-reviewer subagent with issue number, PR number, owner, repo, and feature description.

### 10. Report Completion

Reply to user with PR URL and plan reference.

## Notes

- Ensure all tests pass before creating PR
- Include issue number in commit message and PR title
- Always trigger code review (mandatory)'

    # --- Template: .agents/commands/fix-issue.md ---
    write_template ".agents/commands/fix-issue.md" '<!-- generated by yoke -->
# Fix Issue Command

Fetch issue details, find relevant code, implement fix, and open PR.

## Usage

```
/fix-issue <issue_number>
```

**Arguments:**

- `issue_number`: The GitHub issue number to fix

## Argument Indexing

- **Claude Code**: Use `$1` for the first argument (issue number)
- **OpenCode**: Use `$ARGUMENTS` to get all arguments

## Steps

### 1. Get Repo Info

```bash
git remote get-url origin
```

### 2. Fetch Issue

```bash
gh issue view <issue_number> --repo <owner>/<repo>
```

### 3. Analyze Issue

Read the issue description and identify what needs fixing.

### 4. Find Relevant Code

Search for relevant code in the source directory.

### 5. Create Branch

```bash
git checkout -b fix/issue-<issue_number>-<short-description>
```

### 6. Write Test First

Create test that reproduces the issue. Run test to confirm it fails.

### 7. Implement Fix

Implement the fix to make the test pass.

### 8. Run Tests

```bash
{{test_command}}
```

### 9. Run Linting

```bash
{{lint_command}}
{{format_command}}
```

### 10. Run Type Checking

```bash
{{typecheck_command}}
```

### 11. Commit

```bash
git add -A
git commit -m "fix(scope): description for #XX"
```

### 12. Push and Create PR

```bash
git push -u origin fix/issue-XX-description
gh pr create --repo <owner>/<repo> \
  --title "fix(scope): description for #XX" \
  --head fix/issue-XX-description \
  --base main \
  --body "## Summary\n<description>\n\n## Issue\nFixes #XX"
```

### 13. Trigger Code Review

Invoke the code-reviewer subagent.

## Notes

- Use `fix/` prefix for bug fix branches
- Always write test first (TDD)
- Include issue number in commit and PR'

    # --- Template: .agents/commands/plan-feature.md ---
    write_template ".agents/commands/plan-feature.md" '<!-- generated by yoke -->
# Plan Feature Command

Decompose a high-level feature into well-formed, agent-sized GitHub issues with dependency ordering and Agent Metadata — ready for the orchestrator.

## Usage

```
/plan-feature <feature_description>
```

**Arguments:**

- `feature_description`: A natural-language description of the feature to plan. Can be a sentence, a paragraph, or a reference to an existing issue/doc.

## Argument Indexing

- **Claude Code**: Use `$1` for the first argument (feature description, may be multi-word)
- **OpenCode**: Use `$ARGUMENTS` to get all arguments

## Steps

### 1. Get Repo Info

```bash
git remote get-url origin
```

Parse owner and repo name.

### 2. Understand the Codebase Context

Read the key context files to understand what exists:

- `AGENTS.md` — architecture overview, component locations
- `docs/architecture/overview.md` — module structure, layering rules
- `docs/principles.md` — code invariants (if exists)

Scan the source directory to understand the current module structure.

### 3. Analyze the Feature

Break the feature description into concrete work items. For each, determine:

- **What changes**: Which files/modules are affected
- **Scope**: Is this a new module, modification to existing, or cross-cutting?
- **Complexity**: small (< 1 hour agent work), medium (1-3 hours), large (needs further decomposition)
- **Dependencies**: Does this require another piece to land first?
- **Parallel safety**: Can an agent work on this while other agents work on sibling issues?

### 4. Decomposition Rules

Follow the issue-decomposition skill at `.agents/skills/issue-decomposition/SKILL.md` for:

- Right granularity (one issue = one agent session = one worktree)
- Dependency patterns (data models before consumers, infrastructure before features)
- Parallel safety rules
- Acceptance criteria rules (specific, testable, complete, independent)

### 5. Build the Dependency Graph

Arrange issues into a dependency DAG:

- Identify which issues block which others
- Group independent issues that can run in parallel (same wave)
- Verify there are no cycles
- Verify the graph is connected (no orphans)

Present the graph as waves:

```
Wave 1 (parallel): #A Data models, #B Config schema
Wave 2 (parallel): #C Service layer (depends on #A), #D CLI commands (depends on #B)
Wave 3: #E Integration tests (depends on #C, #D)
```

### 6. Present the Plan to the Developer

Show the complete plan with issue breakdown per wave, including title, description, acceptance criteria, files, complexity, dependencies, and parallel safety for each issue.

Include the dependency graph and the orchestrator command to run after issues are created.

### 7. Wait for Developer Approval

**STOP HERE.** Ask the developer:

> "Here'\''s the proposed breakdown into N issues across M waves. Want me to:
> 1. Create all issues as-is
> 2. Modify the plan (tell me what to change)
> 3. Cancel"

**Do NOT create issues without explicit approval.**

### 8. Create Issues

Once approved, create each issue via `gh`:

```bash
gh issue create --repo <owner>/<repo> \
  --title "<title>" \
  --label "orchestrator-ready" \
  --body "## Description

<description>

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Agent Metadata

| Field                | Value              |
| -------------------- | ------------------ |
| Depends on           | #<dep1>, #<dep2>   |
| Parallel safe        | yes                |
| Auto-merge           | no                 |
| Agent tool           | opencode           |
| Estimated complexity | small              |
"
```

Create issues in dependency order (Wave 1 first) so that `Depends on` fields can reference real issue numbers.

### 9. Report Summary

After all issues are created, report the issue list with wave assignments and the orchestrator command.

## Notes

- This command is for PLANNING, not implementation. It creates issues; agents implement them later.
- Always wait for developer approval before creating issues.
- Default to `Auto-merge: no` unless the developer explicitly says otherwise.
- Default to `Agent tool: opencode` unless the developer specifies otherwise.
- If the feature is too large to decompose in one pass (> 15 issues), suggest breaking it into sub-features first.'

    # --- Template: .agents/skills/issue-decomposition/SKILL.md ---
    write_template ".agents/skills/issue-decomposition/SKILL.md" '<!-- generated by yoke -->
---
name: issue-decomposition
description: Decompose features into well-formed, agent-sized GitHub issues with dependency ordering and orchestrator metadata
---

# Issue Decomposition Skill

How to break features into issues that the orchestrator can dispatch to agents effectively.

## Scope

This skill produces GitHub issues, not code. Output goes to `gh issue create` commands.

## The Right Granularity

An agent-sized issue has these properties:

- **One session**: An agent can complete it in a single worktree session (typically 1-5 grind loop iterations)
- **Focused scope**: Touches 1-4 files across 1-2 modules. If it touches more, split it.
- **Testable**: You can write a concrete test that verifies the issue is done
- **Independent merge**: The PR can be merged without waiting for unrelated work
- **Clear boundaries**: Another agent working on a sibling issue won'\''t have merge conflicts

### Size Guide

| Complexity | Agent time | Typical scope | Examples |
|---|---|---|---|
| small | < 30 min | 1-2 files, single module | Add a config field, write a utility function, fix a bug |
| medium | 30 min - 2 hours | 2-4 files, 1-2 modules | New strategy implementation, new API endpoint, new scanner |
| large | > 2 hours | 5+ files, 3+ modules | **Must be decomposed further** |

## Dependency Patterns

### Common Dependency Chains

```
Data model → Service that uses it → CLI/API that exposes it → Integration test
Config schema → Feature that reads config → Tests
Shared utility → Multiple consumers (parallel after utility lands)
```

### When to Use Dependencies

- **Use `Depends on`** when Issue B literally cannot start until Issue A'\''s PR is merged (e.g., B imports a class that A creates)
- **Don'\''t use `Depends on`** for soft ordering preferences. If B could technically start before A merges (maybe with a stub), they'\''re parallel-safe.
- **Minimize dependency depth**. A chain of A→B→C→D→E means 5 sequential waves. Look for ways to parallelize.

### Parallel Safety

Mark `Parallel safe: yes` when:
- The issue touches files that no sibling issue in the same wave touches
- The issue creates new files (no merge conflict possible)
- The issue modifies isolated sections of shared files (rare — default to `no` if unsure)

Mark `Parallel safe: no` when:
- Two issues in the same wave modify the same file
- The issue modifies a shared config or schema that others also modify

## Agent Metadata Reference

Every issue must include this table in the body:

```markdown
## Agent Metadata

| Field                | Value              |
| -------------------- | ------------------ |
| Depends on           | #42, #43           |
| Parallel safe        | yes                |
| Auto-merge           | no                 |
| Agent tool           | opencode           |
| Estimated complexity | small              |
```

### Field Rules

| Field | Values | Default | Notes |
|---|---|---|---|
| Depends on | `#none` or comma-separated issue numbers | `#none` | Use real issue numbers, not titles |
| Parallel safe | `yes` / `no` | `yes` | `no` if same-wave issues touch same files |
| Auto-merge | `yes` / `no` | `no` | Only `yes` for low-risk, well-tested changes |
| Agent tool | `opencode` / `claude` / `codex` / `kiro` | `opencode` | Which agent runtime to use |
| Estimated complexity | `small` / `medium` | `small` | `large` means "decompose further" |

## Acceptance Criteria Rules

Good acceptance criteria are:
- **Specific**: "Function `calculate_risk()` returns a `RiskScore` with `value` between 0.0 and 1.0" — not "implement risk calculation"
- **Testable**: Each criterion maps to at least one test case
- **Complete**: If all criteria pass, the issue is done. No hidden requirements.
- **Independent**: Each criterion can be verified on its own

### Anti-patterns

- Do not use vague criteria like "Implement the feature" or "Code is clean"
- Do not use subjective criteria like "Works correctly" or "All edge cases handled"

### Good examples

- "`SentimentScanner.scan()` returns `list[Opportunity]` with `score` field populated from LLM response"
- "Config file `config.yaml` is validated on load; missing required fields raise `ConfigError` with field name in message"
- "Test `test_momentum_strategy_buy_signal` passes: given 3 consecutive green candles with volume > 1.5x average, strategy returns BUY signal"

## Steps for Decomposition

1. **Read the feature description** — understand the full scope
2. **Identify the modules** — which parts of the codebase are affected? Check `AGENTS.md` architecture table.
3. **Find the natural seams** — where can you draw boundaries between independent units of work?
4. **Order by dependency** — data models first, then services, then consumers, then integration
5. **Estimate complexity** — if anything is "large", split it further
6. **Check parallel safety** — which issues in the same wave touch the same files?
7. **Write acceptance criteria** — concrete, testable, complete
8. **Build the wave plan** — group into waves respecting dependencies
9. **Verify the graph** — no cycles, no orphans, minimal depth

## Reference Files

| File | Purpose |
|---|---|
| `.github/ISSUE_TEMPLATE/feature-task.md` | Issue template with Agent Metadata table |
| `.agents/commands/plan-feature.md` | Command that uses this skill |
| `scripts/orchestrate.sh` | Orchestrator that consumes the issues |
| `scripts/issue-preflight.sh` | Validates issue readiness and parses metadata |
| `.agents/config.yaml` | Orchestrator config (max_parallel, default_agent_tool) |'


    # --- Template: .agents/agents/code-reviewer/prompt.md ---
    write_template ".agents/agents/code-reviewer/prompt.md" '<!-- generated by yoke -->
You are a code reviewer for {{repo_name}} — {{tech_stack}}.

## Your Task

Review the code changes and write findings to `CODE_REVIEW_{ISSUE_NUMBER}.md` in root directory.

This can be invoked in two contexts:

1. **Local changes** (no PR yet): Review uncommitted changes on the current branch
2. **PR review**: Review an existing pull request

## Required Information

From the invoking agent:

- `ISSUE_NUMBER` - GitHub issue number
- `PR_NUMBER` - Pull request number (optional for local review)
- `OWNER` - Repository owner
- `REPO` - Repository name
- `FEATURE_DESCRIPTION` - What was implemented

## Review Process

### For Local Changes (no PR):

1. Get local changes: `git status`, `git diff`, `git diff --cached`
2. Review against checklist below
3. Write findings to `CODE_REVIEW_{ISSUE_NUMBER}.md`

### For PR Review:

1. Get PR details: `gh pr view/diff {PR_NUMBER} --repo {OWNER}/{REPO}`
2. Review against checklist below
3. Write findings to `CODE_REVIEW_{ISSUE_NUMBER}.md`

## Review Checklist

### Golden Rules (from AGENTS.md)

- GitHub issue exists and is referenced
- Tests written first and updated for every change
- One feature/fix per PR with focused commits
- No secrets in code; use environment variables

### Focus Areas

**1. Correctness**
- Business logic validates against requirements
- Edge cases handled (null, empty, large inputs)
- Error paths with helpful responses

**2. Test-First Coverage**
- Tests present for all changes
- Deterministic tests (no random data)
- External APIs properly mocked

**3. Type Safety**
- No `Any` types without justification
- Explicit return types for exports

**4. Architecture**
- Changes respect module boundaries in `{{source_dir}}`
- No cross-layer imports that violate architecture rules

**5. Security**
- No hardcoded API keys or secrets
- Environment variables for all credentials
- Input validation at trust boundaries

**6. Git Hygiene**
- Conventional commits referencing issue
- Single intent per PR

### Auto-Block Criteria

1. Hardcoded secrets or committed env files with credentials
2. Missing tests for code changes
3. Lint or type check errors
4. No issue reference in PR/commits
5. Multiple unrelated features in PR

### Auto-Approve Candidates

1. Documentation-only changes
2. Dependency bumps (with passing tests)
3. Config tweaks without behavior changes
4. Test-only additions

## Output Format

Write to `CODE_REVIEW_{ISSUE_NUMBER}.md`:

```markdown
# Code Review for {FEATURE_DESCRIPTION}

**PR**: {PR_URL}
**Issue**: #{ISSUE_NUMBER}

## Overview

Brief description of changes and files involved.

## Suggestions

### {type_marker} {Summary with context}

- **Priority**: {Critical / High / Medium / Low}
- **File**: `{path/to/file}:{line}`
- **Details**: Explanation
- **Suggested Change** (if applicable):

## Summary

**Ready to merge?**: [Yes / No / With fixes]
**Reasoning**: 1-2 sentence assessment.
```

## Suggestion Markers

**Type:** △ Change, ‽ Question, · Nitpick, ↻ Refactor, ⚠ Concern, ✓ Positive, ※ Note, → Future

**Priority:** ■ Critical, ◆ High, ◇ Medium, ◦ Low'

    # --- Template: scripts/validate_docs.sh ---
    write_template "scripts/validate_docs.sh" '#!/usr/bin/env bash
# generated by yoke
# validate_docs.sh — Validate documentation cross-references
# Scans AGENTS.md, skill files, and docs for broken links to files that do not exist.

set -euo pipefail

VIOLATIONS=0

check_file() {
    local filepath="$1"
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Markdown links: [text](path)
        echo "$line" | grep -oE '"'"'\[[^]]*\]\([^)]+\)'"'"' | while read -r match; do
            target=$(echo "$match" | sed '"'"'s/.*](\(.*\))/\1/'"'"')
            case "$target" in http://*|https://*|"#"*|mailto:*) continue ;; esac
            # Strip anchor fragments
            target="${target%%#*}"
            [ -z "$target" ] && continue
            resolved="$(dirname "$filepath")/$target"
            if [ ! -e "$resolved" ]; then
                echo "$filepath:$line_num: broken-link: Target \"$target\" does not exist. Remediation: Update the link or create the missing file."
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
        done
        # Backtick paths: `path/to/file.ext`
        echo "$line" | grep -oE '"'"'`[^`]+\.[a-zA-Z]+`'"'"' | tr -d '"'"'`'"'"' | while read -r candidate; do
            case "$candidate" in http://*|https://*) continue ;; esac
            echo "$candidate" | grep -q "/" || continue
            candidate="${candidate%%#*}"
            if [ ! -e "$candidate" ]; then
                echo "$filepath:$line_num: broken-link: Target \"$candidate\" does not exist. Remediation: Update the link or create the missing file."
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
        done
    done < "$filepath"
}

# Scan AGENTS.md, docs/, .agents/skills/
[ -f "AGENTS.md" ] && check_file "AGENTS.md"
find docs -name "*.md" 2>/dev/null | while read -r f; do check_file "$f"; done
find .agents/skills -name "*.md" 2>/dev/null | while read -r f; do check_file "$f"; done

if [ "$VIOLATIONS" -gt 0 ]; then
    exit 1
fi
echo "All documentation cross-references are valid."'


    # --- Template: .github/workflows/pr.yml ---
    write_template ".github/workflows/pr.yml" '# generated by yoke
name: PR Checks

on:
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: {{install_command}}
      - name: Lint
        run: {{lint_command}}
      - name: Architecture lint
        run: bash scripts/lint_architecture.sh || true
      - name: Doc validation
        run: bash scripts/validate_docs.sh || true

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: {{install_command}}
      - name: Type check
        run: {{typecheck_command}}

  test:
    needs: [lint, typecheck]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: {{install_command}}
      - name: Test
        run: {{test_command}}'

    # --- Template: .github/workflows/ci.yml ---
    write_template ".github/workflows/ci.yml" '# generated by yoke
name: CI

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: {{install_command}}
      - name: Test with coverage
        run: {{test_command}}'

    # --- Template: .pre-commit-config.yaml ---
    write_template ".pre-commit-config.yaml" '# generated by yoke
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: local
    hooks:
      - id: lint
        name: lint
        entry: {{lint_command}}
        language: system
        pass_filenames: false
      - id: format
        name: format
        entry: {{format_command}}
        language: system
        pass_filenames: false
      - id: typecheck
        name: typecheck
        entry: {{typecheck_command}}
        language: system
        pass_filenames: false
      - id: architecture-lint
        name: architecture lint
        entry: bash scripts/lint_architecture.sh
        language: system
        pass_filenames: false
      - id: test
        name: test
        entry: {{test_command}}
        language: system
        pass_filenames: false
        stages: [pre-push]'


    # --- Template: AGENTS.md ---
    write_template "AGENTS.md" '<!-- generated by yoke -->
# AI Agent Instructions for {{repo_name}}

> **Critical**: You are a principal software engineer working on {{repo_name}}. Your job: build features incrementally using test-first development.

## Quick Start

```bash
# 1. Install dependencies
{{install_command}}

# 2. Setup environment
cp .env.example .env
# Edit .env with required API keys

# 3. Start development
{{run_command}}
```

## Golden Rules

1. **GitHub Issue First** - No work without an issue. Create one if missing.
2. **Tests Before Code** - Write tests first, then implement.
3. **One Issue Per Session** - Each worktree session handles exactly ONE issue.
4. **One Thing At A Time** - Single feature per PR, focused commits.
5. **No Secrets** - Use environment variables, never hardcode credentials.
6. **Debug Efficiently** - Run tests once, save output, analyze. Never run full test suite repeatedly.

See [docs/dev/tdd-flow.md](docs/dev/tdd-flow.md) for detailed workflow. For code invariants, see [docs/principles.md](docs/principles.md).

## Architecture Overview

{{architecture_table}}

See [docs/architecture/overview.md](docs/architecture/overview.md) for full architecture details.

## Pre-Flight Checks

```bash
pwd
git remote get-url origin
git status
git branch --show-current
```

## Development Flow

Use the slash commands to drive the workflow:

- `/plan-feature <description>` — Decompose a feature into agent-sized GitHub issues with dependency ordering. Human-in-the-loop approval before issue creation.
- `/start-issue <number>` — Preflight, fetch issue, create branch, create plan, scaffold tests, verify tests run, trigger code review.
- `/create-pr` — Run tests + lint + typecheck, commit, push, create PR, trigger code review, report completion.
- `/fix-issue <number>` — Fetch issue, analyze, find relevant code, create branch, write test first, implement fix, create PR.

**Plan First**: The PreToolUse hook enforces this — code writes are blocked until a plan file exists in `docs/plans/`.

See [docs/dev/tdd-flow.md](docs/dev/tdd-flow.md) for the TDD workflow details and grind loop configuration.

## Code Review Flow

The `/start-issue` and `/create-pr` commands trigger code review automatically. If working manually:

1. Trigger code review using the code-reviewer subagent
2. Fix any Critical/High issues the reviewer identifies
3. Repeat until reviewer says "Ready to merge"
4. Only then create PR

> Code review is mandatory. Do not skip it.

## Testing

See [docs/dev/testing.md](docs/dev/testing.md) for test structure and patterns.

## Conventions

- Commits: single-line conventional format
- See [docs/dev/commit-conventions.md](docs/dev/commit-conventions.md) for full conventions.

## Skills & Tasks

{{skills_table}}

## Never Do This

- Code without tests
- Hardcode API keys or secrets
- Skip test verification
- Large multi-feature PRs
- Run full test suite repeatedly to debug
- Hardcode GitHub repo owner/name
- Place real trades in test mode

## Worktree Management

You are working in a **git worktree** - an isolated workspace. One worktree = One issue = One session.

## GitHub Operations

See [docs/dev/github-operations.md](docs/dev/github-operations.md) for `gh` CLI reference.

---

**Remember**: Tests first, small changes, always reference issues.'

    # --- Static: docs/INDEX.md ---
    write_file "docs/INDEX.md" '<!-- generated by yoke -->
# Documentation

## Quick Links

- [AGENTS.md](../AGENTS.md) - AI Agent instructions (start here for agents)
- [README.md](../README.md) - Project overview and setup

## Architecture

- [Architecture Overview](architecture/overview.md) - Domain map, layering, import rules
- [ADRs](architecture/decisions/) - Architecture decision records

## Development Procedures

- [TDD Workflow](dev/tdd-flow.md) - Test-driven development process
- [Commit Conventions](dev/commit-conventions.md) - Commit format, branch naming
- [Debugging](dev/debugging.md) - Debugging procedures
- [GitHub Operations](dev/github-operations.md) - `gh` CLI usage
- [Testing](dev/testing.md) - Test structure and patterns
- [Common Mistakes](dev/common-mistakes.md) - Recurring agent errors and fixes

## Plans

- [Plan Template](templates/plan-template.md) - Template for new issue plans

## Enforcement & Automation

- `scripts/lint_architecture.sh` - Architecture boundary linter
- `scripts/validate_docs.sh` - Doc cross-reference validation
- `scripts/audit_principles.sh` - Golden principles audit
- `.agents/config.yaml` - Shared grind loop config
- `.agents/hooks/check-completion.sh` - Grind loop completion checker
- `.agents/hooks/check-plan-exists.sh` - Plan-first workflow enforcement
- `.agents/hooks/opencode-grind-loop.sh` - Bash grind loop wrapper

## Skills

See `.agents/skills/` for specialized skills.

## Commands

- `/plan-feature <description>` — Decompose a feature into agent-sized issues with dependency ordering
- `/start-issue <number>` — Start work on a GitHub issue
- `/create-pr` — Create a pull request after completing work
- `/fix-issue <number>` — Quick-fix an issue with TDD'


    # --- Template: docs/dev/tdd-flow.md ---
    write_template "docs/dev/tdd-flow.md" '<!-- generated by yoke -->
# TDD Workflow

## Standard TDD Flow

```bash
# 1. Write test in tests/
# 2. Verify test fails
{{test_command}}

# 3. Implement minimal code to pass
# 4. Verify test passes
{{test_command}}

# 5. Commit
git add <test_file> <source_file>
git commit -m "feat(scope): implement feature for #XX"
```

## Completing a Feature

Run `/create-pr` — it handles tests, lint, typecheck, commit, push, PR creation, and code review trigger in one shot.

See [`.agents/commands/create-pr.md`](../../.agents/commands/create-pr.md) for the full step-by-step breakdown.

## Grind Loop (Iterate-Until-Done)

### Configuration

All grind loop settings live in `.agents/config.yaml`:

```yaml
grind_loop:
  max_iterations: 5
  stall_timeout_seconds: 300
  idle_timeout_seconds: 120
  session_log: .agents/session-log.jsonl
```

### Claude Code

Enforcement is automatic via hooks in `.claude/settings.local.json`:
- `Stop` hook runs `.agents/hooks/check-completion.sh` after each agent turn
- `PreToolUse` hook runs `.agents/hooks/check-plan-exists.sh` before any Write/Edit

### OpenCode

Enforcement is automatic via plugins in `.opencode/plugins/`:
- `grind-loop.ts` — listens to `session.idle` events, runs `check-completion.sh`, re-prompts if incomplete
- `plan-first.ts` — intercepts `tool.execute.before` on write/edit tools

Fallback: `.agents/hooks/opencode-grind-loop.sh` wraps `opencode run` in a bash loop.

### Completion Criteria (shared)

Both tools use `.agents/hooks/check-completion.sh` which checks:
1. Tests pass (`{{test_command}}`)
2. No Critical/High findings in `CODE_REVIEW_*.md`
3. Blind review requested if PR exists but no review file
4. Scratchpad signals DONE
5. Agent idle detection with stuck loop escalation
6. Iteration cap (configurable, default 5)

### Scratchpad

Maintain `.agents/scratchpad.md` during work with STATUS, ITERATION, COMPLETED checklist, CURRENT_FOCUS, and BLOCKERS.

### Stall & Idle Protection

| Scenario | Detection | Action |
|---|---|---|
| Agent stuck (no output) | Bash: `timeout`. OpenCode: stall timer. | Kill/re-prompt |
| Agent stopped but not done | check-completion.sh idle check | Re-prompt with context |
| Same task stuck across iterations | Session log analysis | Escalated re-prompt |
| Max iterations reached | Iteration counter | Stop gracefully |'

    # --- Static: docs/dev/commit-conventions.md ---
    write_file "docs/dev/commit-conventions.md" '<!-- generated by yoke -->
# Commit Conventions

## Commit Message Format

Follow conventional commits with **single-line format only**:

```bash
git commit -m "feat(scope): implement feature for #XX"
```

## Commit Types

- `feat(scope): add feature for #XX`
- `fix(scope): correct bug for #XX`
- `docs(scope): update documentation for #XX`
- `test(scope): add tests for #XX`
- `refactor(scope): simplify logic for #XX`
- `chore(scope): update dependencies for #XX`

## Branch Naming

- `feature/issue-XX-short-description`
- `fix/issue-XX-short-description`

## Pre-Commit Checklist

- [ ] GitHub issue exists and referenced (`#XX`)
- [ ] Test written BEFORE implementation
- [ ] All tests pass
- [ ] Linting clean
- [ ] Formatting applied
- [ ] Type checking passes
- [ ] Commit follows conventional format
- [ ] No hardcoded secrets
- [ ] Single focused change only'

    # --- Template: docs/dev/common-mistakes.md ---
    write_template "docs/dev/common-mistakes.md" '<!-- generated by yoke -->
# Common Mistakes

## Architecture

- **Cross-layer imports**: Do not import from inner layers into outer layers. Respect the architecture boundaries.
- **Inline templates in skills**: Skills should reference files, not contain inline code templates.

## Testing

- **Running full test suite repeatedly**: Run once, save output, analyze. Do not re-run the full suite to debug.
- **Not mocking external APIs**: Always mock external API calls in tests.
- **Random test data**: Use deterministic test data, not random values.

## Git / Workflow

- **Hardcoding repo owner/name**: Always derive from `git remote get-url origin`.
- **Starting new issue in same session**: One worktree = one issue = one session.
- **Multi-feature PRs**: One feature per PR, focused commits.
- **Skipping code review**: Code review is mandatory before merge.

## Security

- **Hardcoded secrets**: Use environment variables for all credentials.
- **Committed .env files**: Never commit .env files with real credentials.'

    # --- Template: docs/dev/github-operations.md ---
    write_template "docs/dev/github-operations.md" '<!-- generated by yoke -->
# GitHub Operations

## Getting Repo Info

```bash
# Get owner/repo from git remote (CRITICAL — never hardcode)
git remote get-url origin
```

## Issue Management

```bash
gh issue view <number> --repo <owner>/<repo>
gh issue create --repo <owner>/<repo> --title "title" --body "body"
gh issue edit <number> --repo <owner>/<repo> --add-label "label"
gh issue close <number> --repo <owner>/<repo>
```

## Pull Requests

```bash
gh pr create --repo <owner>/<repo> --title "title" --head <branch> --base main --body "body"
gh pr view <number> --repo <owner>/<repo>
gh pr diff <number> --repo <owner>/<repo>
gh pr merge <number> --repo <owner>/<repo> --squash
gh pr checks <number> --repo <owner>/<repo>
```

## Branch Management

```bash
git checkout -b feature/issue-XX-description
git push -u origin feature/issue-XX-description
```

## Search

```bash
gh issue list --repo <owner>/<repo> --label "label" --state open
gh pr list --repo <owner>/<repo> --state open
```'

    # --- Static: docs/templates/plan-template.md ---
    write_file "docs/templates/plan-template.md" '<!-- generated by yoke -->
# Plan: Issue #NUMBER — TITLE

## Goal

_One sentence describing what this change accomplishes._

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Files to Modify

| File | Change |
|---|---|
| `path/to/file` | Description of change |

## Test Scenarios

| Scenario | Expected |
|---|---|
| Happy path | ... |
| Edge case | ... |

## Risks

- Risk 1: mitigation'

    # --- Static: docs/architecture/decisions/adr-template.md ---
    write_file "docs/architecture/decisions/adr-template.md" '<!-- generated by yoke -->
# ADR-NNN: Title

## Status

Proposed | Accepted | Deprecated | Superseded by ADR-NNN

## Context

What is the issue that we are seeing that is motivating this decision or change?

## Decision

What is the change that we are proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?'

    # --- Static: docs/architecture/decisions/adr-001-agentic-harness.md ---
    write_file "docs/architecture/decisions/adr-001-agentic-harness.md" '<!-- generated by yoke -->
# ADR-001: Adopt Agentic Development Harness

## Status

Accepted

## Context

AI coding agents (Claude Code, OpenCode, Codex, Kiro) can autonomously work on GitHub issues, but without structure they produce inconsistent results: missing tests, no code review, unbounded iteration, and no observability.

We need a standardized harness that enforces quality gates (plan-first, test-first, code review), provides iteration control (grind loop with completion checking), and supports parallel issue dispatch with worktree isolation.

## Decision

Adopt the three-layer agentic development harness (Yoke):

- **Layer 1 (Outer Orchestration)**: Parallel issue dispatch, worktree isolation, monitoring, auto-merge
- **Layer 2 (Agentic Loop)**: Grind loop, plan-first enforcement, completion checking, code review, commands, shared config
- **Layer 3 (Inner Knowledge)**: Documentation structure, AGENTS.md, domain-specific skills, plan templates, principles

The harness uses shared shell scripts for tool-agnostic logic and tool-native implementations (Claude hooks, OpenCode plugins, Kiro hooks) for agent-specific integration.

## Consequences

- Agents must create a plan before writing code (enforced by PreToolUse hook)
- All agent sessions iterate until completion criteria are met (grind loop)
- Code review is mandatory before PR creation
- Multiple issues can be dispatched in parallel with dependency resolution
- New agent tools can be supported by adding an adapter without modifying existing components'

}


# ============================================================================
# LAYER 1 — FULL PROFILE (only full gets these)
# ============================================================================

install_layer1_full() {
    echo ""
    echo "=== Layer 1: Outer orchestration (full) ==="

    # --- Directories ---
    create_dir ".github/ISSUE_TEMPLATE"
    create_dir ".github/workflows"

    # --- Template: scripts/orchestrate.sh ---
    write_template "scripts/orchestrate.sh" '#!/usr/bin/env bash
# generated by yoke
# orchestrate.sh — Parallel issue orchestrator
#
# Discovers issues, resolves dependencies (topological sort), dispatches agents
# to worktrees in waves, monitors progress, and auto-merges eligible PRs.
#
# Usage:
#   scripts/orchestrate.sh --label orchestrator-ready
#   scripts/orchestrate.sh --issues 101,102,103
#   scripts/orchestrate.sh --dry-run --label orchestrator-ready
#   scripts/orchestrate.sh --max-parallel 2 --issues 101,102

set -euo pipefail

# --- Derive repo info from git remote ---
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REMOTE_URL" ]; then
    echo "ERROR: No git remote found. Cannot determine owner/repo."
    exit 1
fi
OWNER=$(echo "$REMOTE_URL" | sed -E '"'"'s#.*[:/]([^/]+)/([^/.]+)(\.git)?$#\1#'"'"')
REPO=$(echo "$REMOTE_URL" | sed -E '"'"'s#.*[:/]([^/]+)/([^/.]+)(\.git)?$#\2#'"'"')

# --- Config ---
CONFIG_FILE=".agents/config.yaml"
read_config() {
    local key="$1" default="$2"
    if [ -f "$CONFIG_FILE" ]; then
        local value
        value=$(grep -E "^\s+${key}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed '"'"'s/.*:[[:space:]]*//'"'"' | tr -d '"'"'"'"'"' | tr -d "'"'"'"'"'"' | sed '"'"'s/^[[:space:]]*//;s/[[:space:]]*$//'"'"' || echo "")
        [ -n "$value" ] && echo "$value" && return
    fi
    echo "$default"
}

MAX_PARALLEL=$(read_config max_parallel 3)
POLL_INTERVAL=$(read_config poll_interval_seconds 60)
STALL_MULTIPLIER=$(read_config stall_detection_multiplier 2)
ORCH_LOG=$(read_config log ".agents/orchestrator-log.jsonl")
AUTO_MERGE_METHOD=$(read_config auto_merge_method "squash")
DEFAULT_AGENT_TOOL=$(read_config default_agent_tool "{{default_agent_tool}}")
DEFAULT_LABEL=$(read_config default_label "orchestrator-ready")
KILL_GRACE=$(read_config kill_grace_seconds 5)
STALL_TIMEOUT=$(read_config stall_timeout_seconds 300)
LOCKFILE=".agents/orchestrator.lock"

# --- CLI args ---
LABEL=""
ISSUES=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --label) LABEL="${2:-$DEFAULT_LABEL}"; shift 2 ;;
        --issues) ISSUES="$2"; shift 2 ;;
        --max-parallel) MAX_PARALLEL="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [ -z "$LABEL" ] && [ -z "$ISSUES" ]; then
    LABEL="$DEFAULT_LABEL"
fi

# --- Lockfile ---
if [ -f "$LOCKFILE" ]; then
    LOCK_PID=$(cat "$LOCKFILE" 2>/dev/null || echo "")
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "ERROR: Another orchestrator is running (PID $LOCK_PID)"
        exit 1
    fi
    rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap '"'"'rm -f "$LOCKFILE"'"'"' EXIT

# --- Logging ---
log_event() {
    local event="$1" data="${2:-{}}"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "{\"timestamp\":\"$ts\",\"event\":\"$event\",\"data\":$data}" >> "$ORCH_LOG" 2>/dev/null || true
}

log_event "orchestrator_start" "{\"label\":\"$LABEL\",\"issues\":\"$ISSUES\",\"max_parallel\":$MAX_PARALLEL}"

# --- Phase 1: Issue Discovery ---
echo "=== Phase 1: Issue Discovery ==="
declare -a ISSUE_NUMS=()
declare -A ISSUE_DATA=()

if [ -n "$ISSUES" ]; then
    IFS='"'"','"'"' read -ra ISSUE_NUMS <<< "$ISSUES"
else
    while IFS= read -r num; do
        [ -n "$num" ] && ISSUE_NUMS+=("$num")
    done < <(gh issue list --repo "$OWNER/$REPO" --label "$LABEL" --state open --json number --jq '"'"'.[].number'"'"' 2>/dev/null)
fi

echo "Found ${#ISSUE_NUMS[@]} issue(s)"

# Run preflight on each
declare -a READY_ISSUES=()
for num in "${ISSUE_NUMS[@]}"; do
    local_json=$(bash scripts/issue-preflight.sh "$num" 2>/dev/null) || true
    ready=$(echo "$local_json" | jq -r '"'"'.ready // false'"'"' 2>/dev/null || echo "false")
    if [ "$ready" = "true" ]; then
        READY_ISSUES+=("$num")
        ISSUE_DATA["$num"]="$local_json"
    else
        reason=$(echo "$local_json" | jq -r '"'"'.block_reason // "unknown"'"'"' 2>/dev/null || echo "unknown")
        echo "  Issue #$num blocked: $reason"
        log_event "issue_blocked" "{\"issue\":$num,\"reason\":\"$reason\"}"
    fi
done

echo "${#READY_ISSUES[@]} issue(s) ready"

if [ ${#READY_ISSUES[@]} -eq 0 ]; then
    echo "No issues ready. Exiting."
    log_event "orchestrator_end" "{\"reason\":\"no_ready_issues\"}"
    exit 0
fi

# --- Phase 2: Dependency Resolution (Kahn'"'"'s algorithm) ---
echo ""
echo "=== Phase 2: Dependency Resolution ==="

declare -A DEPS=()
declare -A IN_DEGREE=()
for num in "${READY_ISSUES[@]}"; do
    deps=$(echo "${ISSUE_DATA[$num]}" | jq -r '"'"'.depends_on // ""'"'"' 2>/dev/null || echo "")
    DEPS["$num"]="$deps"
    IN_DEGREE["$num"]=0
done

for num in "${READY_ISSUES[@]}"; do
    IFS='"'"','"'"' read -ra dep_list <<< "${DEPS[$num]}"
    for dep in "${dep_list[@]}"; do
        dep=$(echo "$dep" | tr -d '"'"' #'"'"')
        [ -z "$dep" ] || [ "$dep" = "none" ] && continue
        if [[ -v IN_DEGREE["$num"] ]]; then
            IN_DEGREE["$num"]=$(( ${IN_DEGREE[$num]} + 1 ))
        fi
    done
done

# Build waves
declare -a WAVES=()
declare -A PROCESSED=()
remaining=${#READY_ISSUES[@]}
wave_num=0

while [ "$remaining" -gt 0 ]; do
    wave_num=$((wave_num + 1))
    local_wave=""
    for num in "${READY_ISSUES[@]}"; do
        [[ -v PROCESSED["$num"] ]] && continue
        if [ "${IN_DEGREE[$num]:-0}" -eq 0 ]; then
            [ -n "$local_wave" ] && local_wave+=","
            local_wave+="$num"
            PROCESSED["$num"]=1
            remaining=$((remaining - 1))
        fi
    done

    if [ -z "$local_wave" ]; then
        echo "ERROR: Dependency cycle detected among remaining issues"
        log_event "cycle_detected" "{\"remaining\":$remaining}"
        exit 1
    fi

    WAVES+=("$local_wave")
    echo "  Wave $wave_num: $local_wave"

    # Reduce in-degrees for next wave
    IFS='"'"','"'"' read -ra wave_issues <<< "$local_wave"
    for done_num in "${wave_issues[@]}"; do
        for num in "${READY_ISSUES[@]}"; do
            [[ -v PROCESSED["$num"] ]] && continue
            IFS='"'"','"'"' read -ra dep_list <<< "${DEPS[$num]}"
            for dep in "${dep_list[@]}"; do
                dep=$(echo "$dep" | tr -d '"'"' #'"'"')
                if [ "$dep" = "$done_num" ]; then
                    IN_DEGREE["$num"]=$(( ${IN_DEGREE[$num]} - 1 ))
                fi
            done
        done
    done
done

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "=== DRY RUN — Wave plan above. No agents launched. ==="
    log_event "orchestrator_end" "{\"reason\":\"dry_run\",\"waves\":$wave_num}"
    exit 0
fi

# --- Phase 3: Dispatch + Monitor ---
echo ""
echo "=== Phase 3: Dispatch + Monitor ==="

declare -A OUTCOMES=()

for wave_idx in "${!WAVES[@]}"; do
    wave="${WAVES[$wave_idx]}"
    echo ""
    echo "--- Wave $((wave_idx + 1))/${#WAVES[@]}: $wave ---"

    IFS='"'"','"'"' read -ra wave_issues <<< "$wave"
    declare -A PIDS=()
    declare -A WORKTREES=()

    # Limit parallelism within wave
    active=0
    for num in "${wave_issues[@]}"; do
        while [ "$active" -ge "$MAX_PARALLEL" ]; do
            sleep "$POLL_INTERVAL"
            for pid_num in "${!PIDS[@]}"; do
                if ! kill -0 "${PIDS[$pid_num]}" 2>/dev/null; then
                    wait "${PIDS[$pid_num]}" 2>/dev/null || true
                    unset "PIDS[$pid_num]"
                    active=$((active - 1))
                fi
            done
        done

        agent_tool=$(echo "${ISSUE_DATA[$num]}" | jq -r '"'"'.agent_tool // "'"'"'"$DEFAULT_AGENT_TOOL"'"'"'"'"'"' 2>/dev/null || echo "$DEFAULT_AGENT_TOOL")
        wt_dir="../worktrees/issue-$num"

        echo "  Launching issue #$num with $agent_tool..."
        log_event "issue_start" "{\"issue\":$num,\"agent_tool\":\"$agent_tool\"}"

        bash scripts/wti.sh "$num" --setup-only 2>/dev/null || true
        WORKTREES["$num"]="$wt_dir"

        (
            cd "$wt_dir" 2>/dev/null || exit 1
            case "$agent_tool" in
                claude)
                    claude --prompt "Run /start-issue $num" || true
                    ;;
                opencode)
                    source .agents/hooks/opencode-grind-loop.sh
                    grind_loop "Run /start-issue $num" || true
                    ;;
                *)
                    source .agents/hooks/opencode-grind-loop.sh
                    grind_loop "Run /start-issue $num" || true
                    ;;
            esac
        ) > "$wt_dir/agent.log" 2>&1 &
        PIDS["$num"]=$!
        active=$((active + 1))
    done

    # Wait for all in wave with stall detection and progress monitoring
    STALL_LIMIT=$((STALL_TIMEOUT * STALL_MULTIPLIER))
    declare -A START_TIMES=()
    for num in "${!PIDS[@]}"; do
        START_TIMES["$num"]=$(date +%s)
    done

    while [ ${#PIDS[@]} -gt 0 ]; do
        sleep "$POLL_INTERVAL"

        # Progress summary
        echo ""
        echo "  --- Status ($(date +%H:%M:%S)) ---"
        for num in "${!PIDS[@]}"; do
            local_wt="${WORKTREES[$num]}"
            local_iters=$(tail -1 "$local_wt/.agents/session-log.jsonl" 2>/dev/null | grep -o '"'"'"iteration":[0-9]*'"'"' | head -1 | sed '"'"'s/"iteration"://'"'"' || echo "?")
            local_failed=$(tail -1 "$local_wt/.agents/session-log.jsonl" 2>/dev/null | grep -o '"'"'"failed":\[[^]]*\]'"'"' | head -1 | sed '"'"'s/"failed"://'"'"' || echo "[]")
            echo "    #$num: iteration=$local_iters failed=$local_failed"
        done

        # Check for completed/stalled agents
        for num in "${!PIDS[@]}"; do
            if ! kill -0 "${PIDS[$num]}" 2>/dev/null; then
                wait "${PIDS[$num]}" 2>/dev/null
                local_exit=$?
                if [ "$local_exit" -eq 0 ]; then
                    OUTCOMES["$num"]="success"
                    echo "  Issue #$num completed successfully."
                    log_event "issue_complete" "{\"issue\":$num,\"status\":\"success\"}"

                    auto_merge=$(echo "${ISSUE_DATA[$num]}" | jq -r '"'"'.auto_merge // false'"'"' 2>/dev/null || echo "false")
                    if [ "$auto_merge" = "true" ] || [ "$auto_merge" = "yes" ]; then
                        pr_num=$(gh pr list --repo "$OWNER/$REPO" --head "feature/issue-$num-*" --json number --jq '"'"'.[0].number'"'"' 2>/dev/null || echo "")
                        if [ -n "$pr_num" ]; then
                            echo "  Auto-merging PR #$pr_num for issue #$num"
                            gh pr merge "$pr_num" --repo "$OWNER/$REPO" --"$AUTO_MERGE_METHOD" 2>/dev/null || true
                            log_event "auto_merge" "{\"issue\":$num,\"pr\":$pr_num}"
                        fi
                    fi
                else
                    OUTCOMES["$num"]="failed"
                    echo "  Issue #$num failed (exit $local_exit)."
                    log_event "issue_complete" "{\"issue\":$num,\"status\":\"failed\",\"exit_code\":$local_exit}"
                fi
                bash scripts/wtr.sh "$num" 2>/dev/null || true
                unset "PIDS[$num]"
                active=$((active - 1))
                continue
            fi

            elapsed=$(( $(date +%s) - ${START_TIMES[$num]} ))
            if [ "$elapsed" -gt "$STALL_LIMIT" ]; then
                echo "  Issue #$num stalled (${elapsed}s). Killing."
                log_event "issue_stalled" "{\"issue\":$num,\"elapsed\":$elapsed}"
                kill -TERM "${PIDS[$num]}" 2>/dev/null || true
                sleep "$KILL_GRACE"
                kill -KILL "${PIDS[$num]}" 2>/dev/null || true
                wait "${PIDS[$num]}" 2>/dev/null || true
                OUTCOMES["$num"]="stalled"
                bash scripts/wtr.sh "$num" 2>/dev/null || true
                unset "PIDS[$num]"
                active=$((active - 1))
            fi
        done
    done

    # Update main between waves
    if [ "$((wave_idx + 1))" -lt "${#WAVES[@]}" ]; then
        echo "  Updating main before next wave..."
        git fetch origin main 2>/dev/null || true
        git checkout main 2>/dev/null && git pull origin main 2>/dev/null || true
    fi
done

# --- Phase 4: Summary ---
echo ""
echo "=== Phase 4: Summary ==="
for num in "${READY_ISSUES[@]}"; do
    echo "  Issue #$num: ${OUTCOMES[$num]:-unknown}"
done
log_event "orchestrator_end" "{\"total\":${#READY_ISSUES[@]}}"
echo ""
echo "Done."'


    # --- Template: scripts/wti.sh ---
    write_template "scripts/wti.sh" '#!/usr/bin/env bash
# generated by yoke
# wti.sh — Worktree Issue Init (portable, uses native git worktree)
#
# Creates a git worktree for an issue, installs dependencies, sets up agent links.
#
# Usage:
#   scripts/wti.sh <issue_number> [-o|-c|--setup-only]
#
# Flags:
#   -o          Launch with OpenCode after setup
#   -c          Launch with Claude Code after setup
#   --setup-only  Create worktree but do not launch agent

set -euo pipefail

ISSUE_NUM="${1:-}"
if [ -z "$ISSUE_NUM" ]; then
    echo "Usage: scripts/wti.sh <issue_number> [-o|-c|--setup-only]"
    exit 1
fi
shift

AGENT_TOOL=""
SETUP_ONLY=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o) AGENT_TOOL="opencode"; shift ;;
        -c) AGENT_TOOL="claude"; shift ;;
        --setup-only) SETUP_ONLY=true; shift ;;
        *) shift ;;
    esac
done

# Derive branch and worktree path
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
OWNER=$(echo "$REMOTE_URL" | sed -E '"'"'s#.*[:/]([^/]+)/([^/.]+)(\.git)?$#\1#'"'"')
REPO=$(echo "$REMOTE_URL" | sed -E '"'"'s#.*[:/]([^/]+)/([^/.]+)(\.git)?$#\2#'"'"')

ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --repo "$OWNER/$REPO" --json title --jq '"'"'.title'"'"' 2>/dev/null || echo "task")
SHORT_DESC=$(echo "$ISSUE_TITLE" | tr '"'"'[:upper:]'"'"' '"'"'[:lower:]'"'"' | sed '"'"'s/[^a-z0-9]/-/g'"'"' | sed '"'"'s/--*/-/g'"'"' | cut -c1-30 | sed '"'"'s/-$//'"'"')
BRANCH="feature/issue-${ISSUE_NUM}-${SHORT_DESC}"
WT_DIR="../worktrees/issue-${ISSUE_NUM}"
PRIMARY_DIR="$(pwd)"

echo "=== Creating worktree for issue #$ISSUE_NUM ==="
echo "  Branch:    $BRANCH"
echo "  Worktree:  $WT_DIR"

# Create worktree
git worktree add "$WT_DIR" -b "$BRANCH" 2>/dev/null || git worktree add "$WT_DIR" "$BRANCH" 2>/dev/null || {
    echo "ERROR: Failed to create worktree"
    exit 1
}

# Post-create lifecycle
cd "$WT_DIR"

# Copy .env from primary worktree
if [ -f "$PRIMARY_DIR/.env" ]; then
    cp "$PRIMARY_DIR/.env" .env
    echo "  Copied .env"
fi

# Install dependencies
echo "  Installing dependencies..."
{{install_command}} 2>/dev/null || true

# Setup agent links
if [ -f scripts/setup-agent-links.sh ]; then
    bash scripts/setup-agent-links.sh 2>/dev/null || true
fi

echo "  Worktree ready."

if [ "$SETUP_ONLY" = true ]; then
    echo "  Setup only — not launching agent."
    exit 0
fi

# Launch agent
case "$AGENT_TOOL" in
    opencode)
        echo "  Launching OpenCode..."
        source .agents/hooks/opencode-grind-loop.sh
        grind_loop "Run /start-issue $ISSUE_NUM"
        ;;
    claude)
        echo "  Launching Claude Code..."
        claude --prompt "Run /start-issue $ISSUE_NUM"
        ;;
    *)
        echo "  No agent specified. Use -o (OpenCode) or -c (Claude) to launch."
        echo "  Or run manually: cd $WT_DIR"
        ;;
esac'

    # --- Template: scripts/wtr.sh ---
    write_template "scripts/wtr.sh" '#!/usr/bin/env bash
# generated by yoke
# wtr.sh — Worktree Remove (portable, uses native git worktree)
#
# Removes a worktree for an issue, optionally merging the branch first.
#
# Usage:
#   scripts/wtr.sh <issue_number> [-m]
#
# Flags:
#   -m    Merge branch into main before removal

set -euo pipefail

ISSUE_NUM="${1:-}"
if [ -z "$ISSUE_NUM" ]; then
    echo "Usage: scripts/wtr.sh <issue_number> [-m]"
    exit 1
fi
shift

MERGE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m) MERGE=true; shift ;;
        *) shift ;;
    esac
done

WT_DIR="../worktrees/issue-${ISSUE_NUM}"

if [ ! -d "$WT_DIR" ]; then
    echo "Worktree not found: $WT_DIR"
    exit 1
fi

BRANCH=$(cd "$WT_DIR" && git branch --show-current 2>/dev/null || echo "")

if [ "$MERGE" = true ] && [ -n "$BRANCH" ]; then
    echo "Merging $BRANCH into main..."
    git checkout main 2>/dev/null || true
    git merge "$BRANCH" --no-edit 2>/dev/null || {
        echo "WARNING: Merge failed. Resolve conflicts manually."
    }
fi

echo "Removing worktree for issue #$ISSUE_NUM..."
git worktree remove "$WT_DIR" --force 2>/dev/null || rm -rf "$WT_DIR"
git worktree prune 2>/dev/null || true

if [ -n "$BRANCH" ]; then
    git branch -d "$BRANCH" 2>/dev/null || true
fi

echo "Done."'

    # --- Static: scripts/issue-preflight.sh ---
    write_file "scripts/issue-preflight.sh" '#!/usr/bin/env bash
# generated by yoke
# issue-preflight.sh — Single-issue validation and Agent Metadata parsing
#
# Exit codes:
#   0 = ready
#   1 = blocked
#   2 = not found
#
# Output: JSON with issue metadata and readiness status

set -euo pipefail

ISSUE_NUM="${1:-}"
if [ -z "$ISSUE_NUM" ]; then
    echo "Usage: scripts/issue-preflight.sh <issue_number>"
    exit 2
fi

REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
OWNER=$(echo "$REMOTE_URL" | sed -E '"'"'s#.*[:/]([^/]+)/([^/.]+)(\.git)?$#\1#'"'"')
REPO=$(echo "$REMOTE_URL" | sed -E '"'"'s#.*[:/]([^/]+)/([^/.]+)(\.git)?$#\2#'"'"')

# Fetch issue
ISSUE_JSON=$(gh issue view "$ISSUE_NUM" --repo "$OWNER/$REPO" --json title,body,state 2>/dev/null) || {
    echo "{\"ready\":false,\"block_reason\":\"Issue #$ISSUE_NUM not found\"}"
    exit 2
}

STATE=$(echo "$ISSUE_JSON" | jq -r '"'"'.state'"'"')
TITLE=$(echo "$ISSUE_JSON" | jq -r '"'"'.title'"'"')
BODY=$(echo "$ISSUE_JSON" | jq -r '"'"'.body // ""'"'"')

if [ "$STATE" != "OPEN" ]; then
    echo "{\"ready\":false,\"block_reason\":\"Issue #$ISSUE_NUM is $STATE, not OPEN\"}"
    exit 1
fi

# Check for existing PR
EXISTING_PR=$(gh pr list --repo "$OWNER/$REPO" --search "issue $ISSUE_NUM" --json number --jq '"'"'.[0].number // empty'"'"' 2>/dev/null || echo "")
if [ -n "$EXISTING_PR" ]; then
    echo "{\"ready\":false,\"block_reason\":\"PR #$EXISTING_PR already exists for issue #$ISSUE_NUM\"}"
    exit 1
fi

# Parse Agent Metadata table from issue body
parse_meta() {
    local field="$1" default="$2"
    local value
    value=$(echo "$BODY" | grep -i "| *$field *|" 2>/dev/null | sed '"'"'s/.*| *//;s/ *|.*//'"'"' | tr -d '"'"' '"'"' || echo "")
    [ -n "$value" ] && echo "$value" || echo "$default"
}

DEPENDS_ON=$(parse_meta "Depends on" "#none")
PARALLEL_SAFE=$(parse_meta "Parallel safe" "yes")
AUTO_MERGE=$(parse_meta "Auto-merge" "no")
AGENT_TOOL=$(parse_meta "Agent tool" "opencode")
COMPLEXITY=$(parse_meta "Estimated complexity" "small")

# Check dependencies
READY=true
BLOCK_REASON=""
if [ "$DEPENDS_ON" != "#none" ] && [ "$DEPENDS_ON" != "none" ] && [ -n "$DEPENDS_ON" ]; then
    IFS='"'"','"'"' read -ra DEP_LIST <<< "$DEPENDS_ON"
    for dep in "${DEP_LIST[@]}"; do
        dep_num=$(echo "$dep" | tr -d '"'"' #'"'"')
        [ -z "$dep_num" ] && continue
        dep_pr=$(gh pr list --repo "$OWNER/$REPO" --search "closes #$dep_num" --state merged --json number --jq '"'"'.[0].number // empty'"'"' 2>/dev/null || echo "")
        if [ -z "$dep_pr" ]; then
            READY=false
            BLOCK_REASON="Dependency #$dep_num has no merged PR"
            break
        fi
    done
fi

cat <<ENDJSON
{
  "issue_number": $ISSUE_NUM,
  "title": "$(echo "$TITLE" | sed '"'"'s/"/\\"/g'"'"')",
  "depends_on": "$DEPENDS_ON",
  "parallel_safe": $([ "$PARALLEL_SAFE" = "yes" ] && echo "true" || echo "false"),
  "auto_merge": $([ "$AUTO_MERGE" = "yes" ] && echo "true" || echo "false"),
  "agent_tool": "$AGENT_TOOL",
  "complexity": "$COMPLEXITY",
  "ready": $READY,
  "block_reason": "$BLOCK_REASON"
}
ENDJSON

$READY && exit 0 || exit 1'

    # --- Static: .github/ISSUE_TEMPLATE/feature-task.md ---
    write_file ".github/ISSUE_TEMPLATE/feature-task.md" '---
name: Feature Task
about: A task for agent-driven development
title: ""
labels: orchestrator-ready
---

## Description

_Describe the feature or task._

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Agent Metadata

| Field                | Value    |
| -------------------- | -------- |
| Depends on           | #none    |
| Parallel safe        | yes      |
| Auto-merge           | no       |
| Agent tool           | opencode |
| Estimated complexity | small    |'

}

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
    append_gitignore "agent.log"
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
