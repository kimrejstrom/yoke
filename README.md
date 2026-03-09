# Yoke

A portable, run-once bootstrap that configures any Git repository with a three-layer agentic development harness. Point your agent at `YOKE_SPEC.md`, answer two questions, and get a production-grade harness for AI-assisted development.

## What It Does

Yoke gives AI coding agents (Claude Code, OpenCode, Codex, Kiro) the structure they need to work reliably on GitHub issues: quality gates, iteration control, plan-first enforcement, code review, and optional parallel orchestration.

After setup, the repo owns everything. No daemon, no lock-in, no version coupling.

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: Outer Orchestration (full profile)                    │
│  Parallel issue dispatch, worktree isolation, auto-merge        │
│  orchestrate.sh → wti.sh / wtr.sh → issue-preflight.sh         │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: Agentic Loop (all profiles)                           │
│  Grind loop, plan-first enforcement, completion checking,       │
│  code review, commands, shared config                           │
│  check-completion.sh ← Claude hooks / OpenCode plugins / bash   │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: Inner Knowledge (standard + full)                     │
│  AGENTS.md, docs structure, skills, principles, plan templates  │
│  Architecture overview, testing guide, debugging guide           │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Copy install.sh and YOKE_SPEC.md into your repo root
cp /path/to/yoke/{install.sh,YOKE_SPEC.md} .

# 2. Point your agent at the spec
# In Claude Code, OpenCode, Kiro, or any agent:
"Read YOKE_SPEC.md and set up the agentic harness for this repository"
```

The agent will:
1. Ask you which profile (minimal / standard / full) and which agent tools you use
2. Run `install.sh` to scaffold the file structure
3. Detect your toolchain (Python/uv, TypeScript/npm, Rust/cargo, Go)
4. Fill in template placeholders with your actual commands
5. Generate tool-native components (hooks, plugins) for your selected agents
6. Analyze your codebase and generate documentation, skills, and architecture docs
7. Validate everything works

## Profiles

| Profile | Layers | What You Get |
|---|---|---|
| `minimal` | L2 | Grind loop, completion checker, plan-first enforcement, scratchpad, shared config. The core agentic loop with quality gates. |
| `standard` | L2 + L3 | Everything in minimal, plus: AGENTS.md, documentation structure, code reviewer, commands (`/start-issue`, `/create-pr`, `/fix-issue`, `/plan-feature`), enforcement scripts, CI workflows, skills. |
| `full` | L1 + L2 + L3 | Everything in standard, plus: parallel issue orchestrator, worktree isolation scripts, issue preflight validation, GitHub issue templates with Agent Metadata. |

Profiles are additive: `minimal ⊂ standard ⊂ full`.

## Supported Agent Tools

| Tool | Integration Model | What Yoke Generates |
|---|---|---|
| Claude Code | Hook-based (Stop + PreToolUse) | `.claude/settings.local.json`, `.claude/commands/*` |
| OpenCode | Event-driven TypeScript plugins | `.opencode/plugins/*.ts`, `.opencode/commands/*` |
| Codex | External bash wrapper | Bash grind loop wrapper |
| Kiro | Hook system (askAgent/runCommand) | `.kiro/hooks/*.json`, `.kiro/steering/*.md` |
| Generic | Bash wrapper | `.agents/hooks/opencode-grind-loop.sh` |

Multiple tools can be selected. All share the same underlying scripts.

## Supported Toolchains

| Config Files | Language | Package Manager |
|---|---|---|
| `pyproject.toml` + `uv.lock` | Python | uv |
| `pyproject.toml` (no uv.lock) | Python | pip |
| `package.json` + `package-lock.json` | TypeScript | npm |
| `package.json` + `yarn.lock` | TypeScript | yarn |
| `package.json` + `pnpm-lock.yaml` | TypeScript | pnpm |
| `Cargo.toml` | Rust | cargo |
| `go.mod` | Go | go |

Detection is automatic. First match wins.

## What Gets Created

### Commands (standard + full)

| Command | Purpose |
|---|---|
| `/plan-feature <description>` | Decompose a feature into agent-sized GitHub issues with dependency ordering. Human-in-the-loop approval before creation. |
| `/start-issue <number>` | Preflight, fetch issue, create branch, create plan, scaffold tests, verify, trigger code review. |
| `/create-pr` | Run tests + lint + typecheck, commit, push, create PR, trigger code review. |
| `/fix-issue <number>` | Fetch issue, analyze, find code, create branch, write test first, implement fix, create PR. |

Commands live in `.agents/commands/` and are symlinked to tool-specific directories.

### Quality Gates

- **Plan-first enforcement**: Code writes are blocked until a plan file exists in `docs/plans/`. Enforced via tool-native hooks that delegate to `check-plan-exists.sh`.
- **Grind loop**: Agents iterate until completion criteria are met (tests pass, code review clean, scratchpad signals done). Configurable max iterations and stall detection.
- **Completion checking**: Structured JSON output from `check-completion.sh` with test results, review findings, idle detection, and follow-up prompts.
- **Code review**: Mandatory before PR creation. Code reviewer agent definition included.

### Orchestrator (full profile)

- **Parallel issue dispatch**: Discovers issues by label or explicit list, resolves dependencies via topological sort, dispatches agents in waves.
- **Worktree isolation**: Each issue gets its own `git worktree`. `wti.sh` creates them, `wtr.sh` cleans them up. Native `git worktree` commands only.
- **Issue preflight**: Validates issues are ready (open, no existing PR, dependencies merged, Agent Metadata parsed).
- **Auto-merge**: Eligible PRs are merged automatically after agent completion.
- **Monitoring**: Stall detection, structured JSONL logging, lockfile management.

### Documentation (standard + full)

- `AGENTS.md` — Master agent instructions with architecture, commands, skills, conventions
- `docs/INDEX.md` — Progressive disclosure entry point
- `docs/architecture/overview.md` — Generated from codebase analysis
- `docs/principles.md` — Code invariants derived from linter/CI config
- `docs/dev/` — TDD workflow, testing guide, debugging guide, commit conventions, common mistakes
- `docs/templates/plan-template.md` — Standard plan format
- `docs/architecture/decisions/` — ADR template + ADR-001 (harness adoption)

### Skills (standard + full)

Skills are detected from codebase patterns and generated as `.agents/skills/*/SKILL.md`:

| Pattern Detected | Skill Generated |
|---|---|
| Pydantic models directory | `pydantic-model/SKILL.md` |
| API route definitions | `new-endpoint/SKILL.md` |
| CLI command definitions | `new-command/SKILL.md` |
| Strategy/plugin pattern | `new-strategy/SKILL.md` |
| Event system | `observability/SKILL.md` |
| Agent/LLM definitions | `new-agent/SKILL.md` |
| Scanner/scraper pattern | `new-scanner/SKILL.md` |

The `issue-decomposition/SKILL.md` skill is always included — it teaches agents how to break features into well-formed, agent-sized issues.

### Enforcement Scripts (standard + full)

- `scripts/lint_architecture.py` — Import boundary checker (generated from codebase analysis)
- `scripts/audit_principles.py` — Principles checker (generated from `docs/principles.md`)
- `scripts/validate_docs.py` — Documentation cross-reference validation

### CI (standard + full)

- `.github/workflows/pr.yml` — Lint + typecheck + test (parallel jobs)
- `.github/workflows/ci.yml` — Main branch test + coverage
- `.pre-commit-config.yaml` — Linter, formatter, type checker, architecture lint, tests

## How It Works

### The Intelligence Boundary

Yoke splits work between mechanical scaffolding and intelligent generation:

**`install.sh` handles** (mechanical, agent-invoked):
- Directory creation
- Writing template files with `{{placeholder}}` markers
- Writing static files (plan template, ADR template, commit conventions)
- Gitignore management

**The agent handles** (intelligent, guided by YOKE_SPEC.md):
- Toolchain detection from config files
- Placeholder substitution across all template files
- Tool-native component generation (architecturally different per tool)
- Codebase analysis → architecture docs, skills, principles
- Validation

### Shared Scripts, Tool-Native Loops

All agent tools share the same underlying scripts:
- `check-completion.sh` — Evaluates whether work is done
- `check-plan-exists.sh` — Decides whether a write should be allowed
- `.agents/config.yaml` — Shared configuration

But the iteration loop is tool-native because each tool has a fundamentally different execution model:
- Claude Code: Hook-based (Stop hook → re-enter automatically)
- OpenCode: Event-driven plugins (session.idle → re-prompt via API)
- Bash wrapper: External for-loop (headless/CI dispatch)

## Configuration

All harness settings live in `.agents/config.yaml`:

```yaml
grind_loop:
  max_iterations: 5
  stall_timeout_seconds: 300
  idle_timeout_seconds: 120
  session_log: .agents/session-log.jsonl

orchestrator:
  max_parallel: 3
  poll_interval_seconds: 60
  auto_merge_method: squash
  default_agent_tool: opencode
  default_label: orchestrator-ready
```

Shell scripts parse this with `grep/awk`. Structured parsers work too.

## Self-Test

```bash
bash install.sh --self-test
```

Runs 32 automated checks in a temp git repo: profile containment, idempotency, gitignore dedup, template placeholder verification, file existence per profile.

## File Manifest


### Minimal Profile (Layer 2)

```
.agents/
├── config.yaml                          # Shared configuration
├── scratchpad.md                        # Agent state tracking
├── hooks/
│   ├── check-completion.sh              # Completion checker (template)
│   ├── check-plan-exists.sh             # Plan-first enforcement (static)
│   └── opencode-grind-loop.sh           # Bash grind loop wrapper (template)
└── skills/
    └── issue-decomposition/SKILL.md     # Issue decomposition skill (template)
```

### Standard Profile adds (Layer 2 + 3)

```
.agents/
├── commands/
│   ├── start-issue.md                   # Start work on an issue (template)
│   ├── create-pr.md                     # Create a pull request (template)
│   ├── fix-issue.md                     # Quick-fix an issue (template)
│   └── plan-feature.md                  # Decompose feature into issues (template)
└── agents/
    └── code-reviewer/prompt.md          # Code reviewer definition (template)

AGENTS.md                                # Master agent instructions (template)
docs/
├── INDEX.md                             # Documentation entry point
├── dev/
│   ├── tdd-flow.md                      # TDD workflow (template)
│   ├── commit-conventions.md            # Commit format
│   ├── common-mistakes.md               # Agent anti-patterns (template)
│   └── github-operations.md             # gh CLI reference (template)
├── templates/
│   └── plan-template.md                 # Plan format
└── architecture/
    └── decisions/
        ├── adr-template.md              # ADR format
        └── adr-001-agentic-harness.md   # Harness adoption record

scripts/
└── validate_docs.py                     # Doc cross-reference checker (template)

.github/workflows/
├── pr.yml                               # PR checks (template)
└── ci.yml                               # Main branch CI (template)

.pre-commit-config.yaml                  # Pre-commit hooks (template)
```

### Full Profile adds (Layer 1)

```
scripts/
├── orchestrate.sh                       # Parallel issue orchestrator (template)
├── wti.sh                               # Worktree init (template)
├── wtr.sh                               # Worktree remove (template)
└── issue-preflight.sh                   # Issue validation (static)

.github/ISSUE_TEMPLATE/
└── feature-task.md                      # Issue template with Agent Metadata
```

### Agent-Generated (not in install.sh)

These are created by the agent during YOKE_SPEC.md steps 4-5, tailored to the repo:

```
# Tool-native (Step 4, per selected tool)
.claude/settings.local.json              # Claude hooks
.claude/commands/*                       # Symlinks to .agents/commands/
.opencode/plugins/grind-loop.ts          # OpenCode grind loop plugin
.opencode/plugins/plan-first.ts          # OpenCode plan-first plugin
.opencode/commands/*                     # Symlinks to .agents/commands/
.kiro/hooks/*.json                       # Kiro hooks
.kiro/steering/*.md                      # Kiro steering files
scripts/setup-agent-links.sh             # Symlink manager

# Content from codebase analysis (Step 5)
docs/architecture/overview.md            # Architecture documentation
docs/principles.md                       # Code invariants
docs/dev/testing.md                      # Testing guide
docs/dev/debugging.md                    # Debugging guide
.agents/skills/*/SKILL.md               # Domain-specific skills
scripts/lint_architecture.py             # Import boundary checker
scripts/audit_principles.py              # Principles checker
```

## Design Principles

1. **Run once, repo owns it**: No daemon, no upgrade mechanism, no version coupling. After init, all files are yours.
2. **Mechanical vs. intelligent**: `install.sh` handles uniform scaffolding. The agent handles everything that benefits from intelligence.
3. **Shared scripts, tool-native loops**: Quality gates are shared. Iteration mechanics are tool-native because each agent has a fundamentally different execution model.
4. **Commands are the canonical workflow**: `.agents/commands/` is the single source of truth. AGENTS.md references commands, orchestrator launches agents with "Run `/start-issue N`".
5. **Idempotent and safe**: install.sh never overwrites existing files. Running it twice is equivalent to running it once.
6. **Progressive profiles**: Start with `minimal` for the core loop, upgrade to `standard` for full knowledge, go `full` for multi-issue orchestration.

## Origin

Yoke was extracted from the [alpacalyzer-algo-trader](https://github.com/kimrejstrom/alpacalyzer-algo-trader) repository, where the harness was developed and battle-tested for autonomous AI-driven trading system development. The patterns were generalized into a repo-agnostic bootstrap.

## License

MIT
