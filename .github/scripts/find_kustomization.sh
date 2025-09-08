#!/bin/bash

# Usage: ./find_kustomization.sh "<space-separated-modified-folders>"
# Output: space-separated relative kustomization folders (no trailing newline)

modified_folders="$1"
declare -A results_set

normalize_path() {
    [[ "$1" != .* ]] && echo "./$1" || echo "$1"
}

process_folder() {
    local folder
    folder=$(normalize_path "$1")

    # --- Folders containing 'base' anywhere ---
    if [[ "$folder" == *base* ]] && [[ $folder =~ .*/([^/]+)/([^/]+)$ ]]; then
        local last_two="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        # Search ./clusters recursively for files containing last_two, omit .git
        while IFS= read -r f; do
            results_set["$(normalize_path "${f%/*}")"]=1
        done < <(grep -rl --exclude-dir=".git" "$last_two" 2>/dev/null)
    fi

    # --- Folders with 'clusters' ---
    if [[ "$folder" == *clusters* ]]; then
        local dir="$folder"
        while [[ "$dir" != "" && "$dir" != "." ]]; do
            for ext in yaml yml; do
                [[ -f "$dir/kustomization.$ext" ]] && { results_set["$dir"]=1; break 2; }
            done
            dir="$(dirname "$dir")"
        done
    fi
}

# Process all modified folders
for folder in $modified_folders; do
    process_folder "$folder"
done

printf -v output "%s " "${!results_set[@]}"
echo -n "${output%" "}"
