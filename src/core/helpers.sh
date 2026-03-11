
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
