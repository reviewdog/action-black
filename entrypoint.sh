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

# Run black with reviewdog
if [ "${INPUT_ANNOTATE}" = 'true' ]; then
  if [ "${INPUT_REPORTER}" = 'github-pr-review' ]; then
    # work only fix diff suggestion
    black --diff --quiet "${INPUT_WORKDIR}/${input_args}" 2>&1 \
      | reviewdog -f="diff"                                    \
      -f.diff.strip=0                                          \
      -name="${INPUT_TOOL_NAME}-fix"                           \
      -reporter="github-pr-review"                             \
      -filter-mode="diff_context"                              \
      -level="${INPUT_LEVEL}"                                  \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}"                  \
      ${INPUT_REVIEWDOG_FLAGS}
  else
    black --check "${INPUT_WORKDIR}/${input_args}" 2>&1 \
      | reviewdog -f="black"                            \
      -name="${INPUT_TOOL_NAME}"                        \
      -reporter="${INPUT_REPORTER:-github-pr-check}"    \
      -filter-mode="${INPUT_FILTER_MODE}"               \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}"           \
      -level="${INPUT_LEVEL}"                           \
      ${INPUT_REVIEWDOG_FLAGS}
  fi
else
  black --check "${INPUT_WORKDIR}/${input_args}" 2>&1
fi

# Also format code if this is requested
# NOTE: Usefull for writing back changes or creating a pull request.
if [ "${INPUT_FORMAT}" = 'true' ]; then
  black "${INPUT_WORKDIR}/${input_args}"
fi
