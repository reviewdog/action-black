#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# If no arguments are given use current working directory
if [ $# -eq 0 ]; then
  input_args="."
else
  input_args="$*"
fi

# Parse reviewdog_flags action argument to filter duplicates
# if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-name"* ]; then
#   rd_name=${INPUT_TOOL_NAME:-black-format}
# fi
# if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-reporter"* ]; then
#   rd_reporter=${INPUT_REPORTER:-github-pr-check}
# fi
# if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-filter-mode"* ]; then
#   rd_filter_mode=${INPUT_FILTER_MODE:-added}
# fi
# if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-fail-on-error"* ]; then
#   rd_fail_on_error=${INPUT_FAIL_ON_ERROR:-false}
# fi
# if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-level"* ]; then
#   rd_level=${INPUT_LEVEL:-error}
# fi

# Run black with reviewdog
if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # work only fix diff suggestion
  cd "${GITHUB_WORKSPACE}" || exit
  black --diff --quiet "${INPUT_WORKDIR}/${input_args}" 2>&1 \
    | reviewdog -f="diff"                                    \
    -f.diff.strip=0                                          \
    -name="${INPUT_TOOL_NAME}-fix"                                   \
    -reporter="github-pr-review"                             \
    -filter-mode="diff_context"                              \
    -level="${INPUT_LEVEL}"                                     \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}"                     \
    ${INPUT_REVIEWDOG_FLAGS}
else
  black --check "${input_args}" 2>&1                 \
    | reviewdog -f="black"                         \
    -name="${INPUT_TOOL_NAME}"                             \
    -reporter="${INPUT_REPORTER:-github-pr-check}"    \
    -filter-mode="${INPUT_FILTER_MODE}"               \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}"           \
    -level="${INPUT_LEVEL}"                           \
    ${INPUT_REVIEWDOG_FLAGS}
fi