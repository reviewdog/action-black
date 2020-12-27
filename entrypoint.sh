#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# If no arguments are given use current working directory
if [ "$#" -eq 0 ]; then
  input_args="."
else
  input_args="$*"
fi

# Setup black and reviewdog commands (Done based on reporter type)
black_args="${INPUT_WORKDIR}/${input_args}"
reviewdog_args="\
  -level=${INPUT_LEVEL:-error} \
  -fail-on-error=${INPUT_FAIL_ON_ERROR:-false} \
  ${INPUT_REVIEWDOG_FLAGS}"
if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
  black_args="${black_args} --diff --quiet"
  reviewdog_args="
    ${reviewdog_args} \
    -f=diff \
    -f.diff.strip=0 \
    -name=${INPUT_TOOL_NAME:-black}-fix \
    -reporter=github-pr-review \
    -filter-mode=diff_context"
else
  black_args="${black_args} --check"
  reviewdog_args=" \
    -f=black \
    -name=${INPUT_TOOL_NAME:-black} \
    -reporter=${INPUT_REPORTER:-github-pr-check} \
    -filter-mode=${INPUT_FILTER_MODE:-added}"
fi

# Run black (with reviewdog)
if [ "${INPUT_ANNOTATE:-true}" = 'true' ]; then
  black ${black_args} --quiet 2>&1 | reviewdog ${reviewdog_args}
else
  black ${black_args} --quiet
fi

# Also format code if this is requested
# NOTE: Usefull for writing back changes or creating a pull request.
if [ "${INPUT_FROMAT:-false}" = 'true' ]; then
  black "${INPUT_WORKDIR}/${input_args}"
fi
