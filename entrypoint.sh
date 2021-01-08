#!/bin/bash
# NOTE: ${VAR,,} Is bash 4.0 syntax to make strings lowercase.

set -eu # Increase bash strictness
set -o pipefail

if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# If no arguments are given use current working directory
black_args=(".")
if [[ "$#" -eq 0 && "${INPUT_BLACK_FLAGS}" != "" ]]; then
  black_args+=(${INPUT_BLACK_FLAGS})
elif [[ "$#" -ne 0 && "${INPUT_BLACK_FLAGS}" != "" ]]; then
  black_args+=($* ${INPUT_BLACK_FLAGS})
elif [[ "$#" -ne 0 && "${INPUT_BLACK_FLAGS}" == "" ]]; then
  black_args+=($*)
fi

# Run black with reviewdog
black_exit_val="0"
reviewdog_exit_val="0"
if [[ "${INPUT_REPORTER}" = 'github-pr-review' ]]; then
  echo "[action-black] Checking python code with the black formatter and reviewdog..."
  black_check_output="$(black --diff --quiet --check ${black_args[*]})" ||
    black_exit_val="$?"

  # Intput black formatter output to reviewdog
  echo "${black_check_output}" | reviewdog -f="diff" \
    -f.diff.strip=0 \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="github-pr-review" \
    -filter-mode="diff_context" \
    -level="${INPUT_LEVEL}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR,,}" \
    ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"
else

  # Remove '-q' and '--quiet' form the black arguments
  # NOTE: Having these flags in the action prevents the action from working.
  black_args_tmp=()
  for item in "${black_args[@]}"; do
    if [[ "${item}" != "-q" && "${item}" != "--quiet" ]]; then
      black_args_tmp+=("${item}") #Quotes when working with strings
    fi
  done

  echo "[action-black] Checking python code with the black formatter and reviewdog..."
  black_check_output="$(black --check ${black_args_tmp[*]} 2>&1)" ||
    black_exit_val="$?"

  # Intput black formatter output to reviewdog
  echo "${black_check_output}" | reviewdog -f="black" \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR,,}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"
fi

# Check for black/reviewdog errors
if [[ "${black_exit_val}" -eq "0" && "${reviewdog_exit_val}" -eq "0" ]]; then
  black_error="false"
  reviewdog_error="false"
elif [[ "${black_exit_val}" -eq "1" && "${reviewdog_exit_val}" -eq "0" ]]; then
  black_error="true"
  reviewdog_error="false"
elif [[ "${black_exit_val}" -eq "1" && "${reviewdog_exit_val}" -eq "1" ]]; then
  black_error="true"
  reviewdog_error="true"
elif [[ "${black_exit_val}" -eq "0" && "${reviewdog_exit_val}" -eq "1" ]]; then
  black_error="false"
  reviewdog_error="true"
elif [[ "${black_exit_val}" -eq "123" && "${reviewdog_exit_val}" -eq "1" ]]; then
  black_error="true"
  reviewdog_error="true"
  echo "[action-black] ERROR: Black found a syntax error when checking the" \
    "files (error code: ${black_exit_val})."
elif [[ "${black_exit_val}" -eq "123" && "${reviewdog_exit_val}" -eq "0" ]]; then
  black_error="true"
  reviewdog_error="false"
  echo "[action-black] ERROR: Black found a syntax error when checking the" \
    "files (error code: ${black_exit_val})."
else
  if [[ "${black_exit_val}" -eq "123" && "${reviewdog_exit_val}" -ne "0" && \
    "${reviewdog_exit_val}" -ne "1" ]]; then
    echo "[action-black] ERROR: Black found a syntax error when checking the" \
      "files (error code: ${black_exit_val})."
    echo "[action-black] ERROR: Something went wrong while trying to run the" \
      "reviewdog error annotator (error code: ${reviewdog_exit_val})."
  elif [[ "${black_exit_val}" -ne "0" && "${black_exit_val}" -ne "1" && \
    "${reviewdog_exit_val}" -ne "0" && "${reviewdog_exit_val}" -ne "1" ]]; then
    echo "[action-black] ERROR: Something went wrong while trying to run the black" \
      "formatter while annotating the changes using reviewdog (black error code:" \
      "${black_exit_val}, reviewdog error code: ${reviewdog_exit_val})."
  elif [[ "${black_exit_val}" -ne "0" && "${black_exit_val}" -ne "1" ]]; then
    echo "[action-black] ERROR: Something went wrong while trying to run the black" \
      "formatter (error code: ${black_exit_val})."
  else
    echo "[action-black] ERROR: Something went wrong while trying to run the" \
      "reviewdog error annotator (error code: ${reviewdog_exit_val})."
  fi
  exit 1
fi

# Throw error if an error occurred and fail_on_error is true
if [[ "${INPUT_FAIL_ON_ERROR,,}" = 'true' && ("${black_error}" = 'true' || \
  "${reviewdog_error}" = 'true') ]]; then
  exit 1
fi
