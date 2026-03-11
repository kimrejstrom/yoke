# Source Files for install.sh

This directory contains the modular source files that are concatenated to generate `install.sh`.

## Structure

```
src/
├── core/
│   ├── header.sh       # Shebang, usage, argument parsing
│   ├── helpers.sh      # Helper functions (create_dir, write_*, append_gitignore)
│   └── self-test.sh    # Self-test function (32 checks)
├── templates/
│   ├── check-completion.sh      # Grind loop completion checker
│   └── opencode-grind-loop.sh   # Bash grind loop wrapper
└── layers/              # TODO: Extract layer installation functions
    ├── layer2-minimal.sh
    ├── layer2-standard.sh
    └── layer1-full.sh
```

## Development Workflow

1. **Edit source files** in `src/`
2. **Rebuild**: `bash build.sh`
3. **Test**: `bash install.sh --self-test`
4. **Commit**: Pre-commit hook auto-rebuilds if `src/` changed

## Build Script

`build.sh` concatenates source files and embeds templates as heredocs:

```bash
bash build.sh  # Generates install.sh
```

## Template Syntax Checking

Templates can be checked independently:

```bash
bash -n src/templates/check-completion.sh
bash -n src/templates/opencode-grind-loop.sh
```

## Pre-Commit Hook

Automatically rebuilds `install.sh` when `src/` files are committed:

```bash
# .git/hooks/pre-commit
# Runs: bash build.sh && git add install.sh
```

## Distribution

`install.sh` remains a single, self-contained file for easy distribution. Users never need to know about `src/` or `build.sh`.
