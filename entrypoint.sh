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
  # erroformat: https://git.io/JeGMU
  echo "ERROR: github-pr-review unsupported (for the black formatter)"
  exit 1
else
  black --check ${input_args} 2>&1 \
    | reviewdog -f="black" \
        -name="${INPUT_TOOL_NAME}" \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        ${INPUT_REVIEWDOG_FLAGS}
fi