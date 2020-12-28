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
black_exit_val="0"
reviewdog_error="false"
if [[ "${INPUT_ANNOTATE}" = 'true' ]]; then
  if [[ "${INPUT_REPORTER}" = 'github-pr-review' ]]; then
    echo "[action-black] Checking python code with the black formatter and reviewdog..."
    # work only fix diff suggestion (std_out: diff, std_err: console output)
    black --diff --quiet --check "${INPUT_WORKDIR}/${black_args}" |
      reviewdog -f="diff"                                   \
        -f.diff.strip=0                                     \
        -name="${INPUT_TOOL_NAME}-fix"                      \
        -reporter="github-pr-review"                        \
        -filter-mode="diff_context"                         \
        -level="${INPUT_LEVEL}"                             \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"             \
        ${INPUT_REVIEWDOG_FLAGS} || reviewdog_error="true"
    black_exit_val="${PIPESTATUS[0]}"

    # Check whether black found formatting errors
    if [[ "${black_exit_val}" -eq "0" ]]; then
      black_error="false"
    elif [[ "${black_exit_val}" -eq "1" ]]; then
      black_error="true"
    else
      echo "Something went wrong while trying to run the black command (error code: ${black_exit_val})."
      exit 1
    fi
  else
    echo "[action-black] Checking python code with the black formatter and reviewdog..."
    black --check "${INPUT_WORKDIR}/${black_args}" 2>&1 |
      reviewdog -f="black"                                  \
        -name="${INPUT_TOOL_NAME}"                          \
        -reporter="${INPUT_REPORTER}"                       \
        -filter-mode="${INPUT_FILTER_MODE}"                 \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}"             \
        -level="${INPUT_LEVEL}"                             \
        ${INPUT_REVIEWDOG_FLAGS} || reviewdog_error="true"
    black_exit_val="${PIPESTATUS[0]}"

    # Check whether black found formatting errors
    if [[ "${black_exit_val}" -eq "0" ]]; then
      black_error="false"
    elif [[ "${black_exit_val}" -eq "1" ]]; then
      black_error="true"
    else
      echo "[action-black] ERROR: Something went wrong while trying to run the black formatter (error code: ${black_exit_val})."
      exit 1
    fi
  fi
else
  echo "[action-black] Checking python code using the black formatter..."
  black --check "${INPUT_WORKDIR}/${black_args}" 2>&1 || black_exit_val="$?"

  # Check whether black found formatting errors
  if [[ "${black_exit_val}" -eq "0" ]]; then
    black_error="false"
  elif [[ "${black_exit_val}" -eq "1" ]]; then
    black_error="true"
  else
    echo "[action-black] ERROR: Something went wrong while trying to run the black formatter (error code: ${black_exit_val})."
    exit 1
  fi
fi

# Also format code if this is requested
# NOTE: Useful for writing back changes or creating a pull request.
black_format_exit_val="0"
if [[ "${INPUT_FORMAT}" = 'true' && "${black_error}" = 'true' ]]; then
  echo "[action-black] Formatting python code using the black formatter..."
  black "${INPUT_WORKDIR}/${black_args}" || black_format_exit_val="$?"

  # Check whether black found formatting errors
  if [[ "${black_format_exit_val}" -eq "0" ]]; then
    echo "::set-output name=is_formatted::true"
  elif [[ "${black_format_exit_val}" -eq "1" ]]; then
    black_error="true"
    echo "::set-output name=is_formatted::false"
  else
    echo "[action-black] ERROR: Something went wrong while trying to run the black formatter (error code: ${black_exit_val})."
    exit 1
  fi
elif [[ "${INPUT_FORMAT}" = 'true' && "${black_error}" != 'true' ]]; then
  echo "[action-black] Formatting not needed."
  echo "::set-output name=is_formatted::false"
fi

# Throw error if an error occurred and fail_on_error is true
if [[ ("${reviewdog_error}" = 'true' || "${black_error}") && "${INPUT_FAIL_ON_ERROR}" = 'true' ]]; then
  exit 1
fi
