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
if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-name"* ]; then
  rd_name=${INPUT_TOOL_NAME:-black-format}
fi
if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-reporter"* ]; then
  rd_reporter=${INPUT_REPORTER:-github-pr-check}
fi
if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-filter-mode"* ]; then
  rd_filter_mode=${INPUT_FILTER_MODE:-added}
fi
if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-fail-on-error"* ]; then
  rd_fail_on_error=${INPUT_FAIL_ON_ERROR:-false}
fi
if [ "${INPUT_REVIEWDOG_FLAGS}" != *"-level"* ]; then
  rd_level=${INPUT_FAIL_ON_ERROR:-false}
fi

# Run black with reviewdog
if [ "${rd_reporter}" = 'github-pr-review' ]; then
  # work only fix diff suggestion
  cd "${GITHUB_WORKSPACE}" || exit
  black --diff --quiet "${INPUT_WORKDIR}/${input_args}" 2>&1 \
    | reviewdog -f="diff"                                    \
    -f.diff.strip=0                                          \
    -name="${rd_name}-fix"                                   \
    -reporter="github-pr-review"                             \
    -filter-mode="diff_context"                              \
    -level="${rd_level}"                                     \
    -fail-on-error="${rd_fail_on_error}"                     \
    "${INPUT_REVIEWDOG_FLAGS}"
else
  black --check ${input_args} 2>&1                 \
    | reviewdog -f="black"                         \
    -name="${rd_name}"                             \
    -reporter="${rd_reporter:-github-pr-check}"    \
    -filter-mode="${rd_filter_mode}"               \
    -fail-on-error="${rd_fail_on_error}"           \
    -level="${rd_level}"                           \
    "${INPUT_REVIEWDOG_FLAGS}"
fi