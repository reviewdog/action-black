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

if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  # work only fix diff suggestion
  cd "${GITHUB_WORKSPACE}" || exit
  black --diff --quiet "${INPUT_WORKDIR}/${input_args}" 2>&1 \
    | reviewdog -f="diff"                                    \
    -f.diff.strip=0                                          \
    -name="${INPUT_TOOL_NAME}-fix"                           \
    -reporter="github-pr-review"                             \
    -filter-mode="diff_context"                              \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}"                  \
    -level="${INPUT_LEVEL}"                                  \
    "${INPUT_REVIEWDOG_FLAGS}"
else
  black --check ${input_args} 2>&1                 \
    | reviewdog -f="black"                         \
    -name="${INPUT_TOOL_NAME}"                     \
    -reporter="${INPUT_REPORTER:-github-pr-check}" \
    -filter-mode="${INPUT_FILTER_MODE}"            \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}"        \
    -level="${INPUT_LEVEL}"                        \
    "${INPUT_REVIEWDOG_FLAGS}"
fi
