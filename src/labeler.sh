#!/usr/bin/env bash
set -euo pipefail

# --- Existing Functions ---

language_labels=()

labeler::label() {
  local -r xs_label="${1}"
  local -r s_label="${3}"
  local -r m_label="${5}"
  local -r l_label="${7}"
  local -r xl_label="${9}"
  local -r fail_if_xl="${10}"
  local -r message_if_xl="${11}"
  local -r files_to_ignore="${12}"
  local -r ignore_line_deletions="${13}"
  local -r ignore_file_deletions="${14}"

  local -r pr_number=$(github_actions::get_pr_number)
  local -r total_modifications=$(github::calculate_total_modifications "$pr_number" "${files_to_ignore[*]}" "$ignore_line_deletions" "$ignore_file_deletions")

  log::message "Total modifications (additions + deletions): $total_modifications"
  log::message "Ignoring files (if present): $files_to_ignore"

  local -r label_to_add=$(labeler::label_for "$total_modifications" "$@")

  log::message "Labeling pull request with size label: $label_to_add"

  github::add_label_to_pr "$pr_number" "$label_to_add" "$xs_label" "$s_label" "$m_label" "$l_label" "$xl_label"

  # If the PR size label is "xl", handle the extra messages or failure as before.
  if [ "$label_to_add" == "$xl_label" ]; then
    if [ -n "$message_if_xl" ] && ! github::has_label "$pr_number" "$label_to_add"; then
      github::comment "$message_if_xl"
    fi

    if [ "$fail_if_xl" == "true" ]; then
      echoerr "PR is xl, please, shorten this!"
      exit 1
    fi
  fi

  # ---- Add Language Labeling ----
  log::message "Detecting languages in changed files..."
  labeler::add_language_labels "$pr_number"
  local all_new_labels=("${language_labels[@]}" "$label_to_add")
  github::add_labels_to_pr "$pr_number" "${all_new_labels[@]}"
}

labeler::label_for() {
  local -r total_modifications=${1}
  local -r xs_label="${2}"
  local -r xs_max_size=${3}
  local -r s_label="${4}"
  local -r s_max_size=${5}
  local -r m_label="${6}"
  local -r m_max_size=${7}
  local -r l_label="${8}"
  local -r l_max_size=${9}
  local -r xl_label="${10}"

  if [ "$total_modifications" -lt "$xs_max_size" ]; then
    label="$xs_label"
  elif [ "$total_modifications" -lt "$s_max_size" ]; then
    label="$s_label"
  elif [ "$total_modifications" -lt "$m_max_size" ]; then
    label="$m_label"
  elif [ "$total_modifications" -lt "$l_max_size" ]; then
    label="$l_label"
  else
    label="$xl_label"
  fi

  echo "$label"
}

# --- New Functions for Language Labeling ---

# This helper adds a label to the PR.
# (If you already have a similar function in your repository, you can replace this.)
github::add_label() {
  local pr_number="$1"
  local label="$2"
  curl -s -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"labels\": [\"${label}\"]}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${pr_number}/labels" > /dev/null
}

# This function fetches changed files, determines languages from file extensions,
# and adds corresponding language labels (prefixed with "pr: lang/").
labeler::add_language_labels() {
  local pr_number="$1"
  
  # Create a temporary directory for the changed files.
  local tmp_dir
  tmp_dir=$(mktemp -d)
  
  # Determine changed files. You may adjust this diff range as needed.
  # This example uses 'origin/main' as the base.
  local changed_files
  changed_files=$(git diff --name-only origin/main...HEAD)
  
  # Copy each changed file into the temporary directory preserving structure.
  for file in $changed_files; do
    if [ -f "$file" ]; then
      mkdir -p "$tmp_dir/$(dirname "$file")"
      cp "$file" "$tmp_dir/$file"
    fi
  done

  # Run Linguist on the temporary directory. Ensure that Ruby and the github-linguist gem are installed.
  local linguist_output
  linguist_output=$(linguist --breakdown "$tmp_dir")
  
  # Debug: Output the linguist breakdown.
  log::message "Linguist output:"
  log::message "$linguist_output"
  
  # Parse Linguist output to get language names.
  # Expected output lines: "LanguageName  xx.xx%"
  local -a languages=()
  while IFS= read -r line; do
    # Skip empty lines.
    [ -z "$line" ] && continue
    # Extract the language name (first column)
    local lang
    lang=$(echo "$line" | awk '{print $1}')
    # Optionally, skip a generic "Other" language.
    if [ "$lang" = "Other" ]; then
      continue
    fi
    # Build a label and convert to lowercase.
    languages+=("pr: lang/$(echo "$lang" | tr '[:upper:]' '[:lower:]')")
  done <<< "$linguist_output"
  
  # Clean up temporary directory.
  rm -rf "$tmp_dir"
  # Add each detected language label to the PR.
  for lang_label in "${!languages[@]}"; do
    language_labels+=("$lang_label")
    log::message "Adding language label: ${lang_label}"
  done
  
}