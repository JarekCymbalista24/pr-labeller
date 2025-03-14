#!/usr/bin/env bash

source "$PR_SIZE_LABELER_HOME/src/ensure.sh"
source "$PR_SIZE_LABELER_HOME/src/github.sh"
source "$PR_SIZE_LABELER_HOME/src/github_actions.sh"
source "$PR_SIZE_LABELER_HOME/src/labeler.sh"
source "$PR_SIZE_LABELER_HOME/src/misc.sh"

##? Adds a size label to a GitHub Pull Request
##?
##? Usage:
##?   main.sh --github_token=<token> --xs_label=<label> --xs_max_size=<size> --s_label=<label> --s_max_size=<size> --m_label=<label> --m_max_size=<size> --l_label=<label> --l_max_size=<size> --xl_label=<label> --fail_if_xl=<false> --message_if_xl=<message> --github_api_url=<url> --files_to_ignore=<files> --ignore_line_deletions=<false> --ignore_file_deletions=<false> --language_labels=<labels>
main() {
  eval "$(/root/bin/docpars -h "$(grep "^##?" "$PR_SIZE_LABELER_HOME/src/main.sh" | cut -c 5-)" : "$@")"

  ensure::env_variable_exist "GITHUB_REPOSITORY"
  ensure::env_variable_exist "GITHUB_EVENT_PATH"

  export GITHUB_TOKEN="$github_token"
  export GITHUB_API_URL="$github_api_url"

  log::message "Language labels: ${language_labels}"
  log::message "GitHub API URL: $GITHUB_API_URL"

  labeler::label \
    "$xs_label" \
    "$xs_max_size" \
    "$s_label" \
    "$s_max_size" \
    "$m_label" \
    "$m_max_size" \
    "$l_label" \
    "$l_max_size" \
    "$xl_label" \
    "$fail_if_xl" \
    "$message_if_xl" \
    "$files_to_ignore" \
    "$ignore_line_deletions" \
    "$ignore_file_deletions" \
    "$language_labels"
  exit $?
}
