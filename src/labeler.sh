#!/usr/bin/env bash

labeler::label() {
  local pr_number
  pr_number=$(github_actions::get_pr_number)
  
  # Calculate total modifications (existing functionality)
  local total_modifications
  total_modifications=$(github::calculate_total_modifications "$pr_number" "${FILES_TO_IGNORE:-}" "${IGNORE_LINE_DELETIONS:-false}" "${IGNORE_FILE_DELETIONS:-false}")
  echo "Total modifications (additions + deletions): $total_modifications"
  
  # Calculate the size label.
  local size_label
  size_label=$(labeler::label_for "$total_modifications" "size/xs" "10" "size/s" "100" "size/m" "500" "size/l" "1000" "size/xl")
  echo "Size label: $size_label"
  
  # Process language labels input (if provided).
  local lang_labels=""
  if [ -n "${LANGUAGE_LABELS:-}" ]; then
    # Convert comma-separated list to newline-separated list.
    lang_labels=$(echo "$LANGUAGE_LABELS" | tr ',' '\n' | xargs -I {} echo "{}")
    echo "Language labels: $lang_labels"
  fi
  
  # Combine the size label with the language labels.
  local combined_labels
  if [ -n "$lang_labels" ]; then
    combined_labels=$(printf "%s,%s" "$size_label" "$(echo "$lang_labels" | tr '\n' ',')")
    combined_labels=${combined_labels%,} # Remove trailing comma
  else
    combined_labels="$size_label"
  fi

  echo "Combined labels: $combined_labels"
  
  # Use github::add_label_to_pr to update the PR with all labels.
  github::add_label_to_pr "$pr_number" "$combined_labels" "size/xs" "size/s" "size/m" "size/l" "size/xl"
}


labeler::label_for() {
  local -r total_modifications="${1}"
  local -r xs_label="${2}"
  local -r xs_max_size="${3}"
  local -r s_label="${4}"
  local -r s_max_size="${5}"
  local -r m_label="${6}"
  local -r m_max_size="${7}"
  local -r l_label="${8}"
  local -r l_max_size="${9}"
  local -r xl_label="${10}"
  
  if [ "$total_modifications" -lt "$xs_max_size" ]; then
    echo "$xs_label"
  elif [ "$total_modifications" -lt "$s_max_size" ]; then
    echo "$s_label"
  elif [ "$total_modifications" -lt "$m_max_size" ]; then
    echo "$m_label"
  elif [ "$total_modifications" -lt "$l_max_size" ]; then
    echo "$l_label"
  else
    echo "$xl_label"
  fi
}