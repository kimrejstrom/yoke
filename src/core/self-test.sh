
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
