#!/bin/bash
set -e

if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# If no arguments are given use current working directory
if [[ "$#" -eq 0 ]]; then
  black_args="."
else
  black_args="$*"
fi

# Run black with reviewdog
black_error="false"
reviewdog_error="false"
if [[ "${INPUT_ANNOTATE}" = 'true' ]]; then
  if [[ "${INPUT_REPORTER}" = 'github-pr-review' ]]; then
    echo "[action-black] Checking python code with the black formatter and reviewdog..."
    # work only fix diff suggestion
    black --diff --quiet "${INPUT_WORKDIR}/${black_args}" 2>&1 |
      reviewdog -f="diff" \
        -f.diff.strip=0 \
        -name="${INPUT_TOOL_NAME}-fix" \
        -reporter="github-pr-review" \
        -filter-mode="diff_context" \
        -level="${INPUT_LEVEL}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        ${INPUT_REVIEWDOG_FLAGS} || reviewdog_error="true"
    black_exit_val="${PIPESTATUS[0]}"
    if [[ "${black_exit_val}" -ne "0" ]]; then
      black_error="true"
    fi
  else
    echo "[action-black] Checking python code with the black formatter and reviewdog..."
    black --check "${INPUT_WORKDIR}/${black_args}" 2>&1 |
      reviewdog -f="black" \
        -name="${INPUT_TOOL_NAME}" \
        -reporter="${INPUT_REPORTER}" \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}" \
        ${INPUT_REVIEWDOG_FLAGS} || reviewdog_error="true"
    black_exit_val="${PIPESTATUS[0]}"
    if [[ "${black_exit_val}" -ne "0" ]]; then
      black_error="true"
    fi
  fi
else
  echo "[action-black] Checking python code using the black formatter..."
  black --check "${INPUT_WORKDIR}/${black_args}" 2>&1 || black_error="true"
fi

# Also format code if this is requested
# NOTE: Useful for writing back changes or creating a pull request.
if [[ "${INPUT_FORMAT}" = 'true' && "${black_error}" = 'true' ]]; then
  echo "[action-black] Formatting python code using the black formatter..."
  black "${INPUT_WORKDIR}/${black_args}" || black_error="true"
elif [[ "${INPUT_FORMAT}" = 'true' && "${black_error}" != 'true' ]]; then
  echo "[action-black] Formatting not needed."
fi

# Throw error if an error occurred and fail_on_error is true
if [[ ("${reviewdog_error}" = 'true' || "${black_error}") && "${INPUT_FAIL_ON_ERROR}" = 'true' ]]; then
  exit 1
fi
