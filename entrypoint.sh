#!/bin/bash
# <!--alex disable black-->

set -eu # Increase bash strictness.
set -o pipefail

if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

export REVIEWDOG_VERSION=v0.20.2

echo "[action-black] Installing reviewdog..."
wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /tmp "${REVIEWDOG_VERSION}"
echo "[action-black] Reviewdog version: ${REVIEWDOG_VERSION}"

if [[ "$(which black)" == "" ]]; then
  echo "[action-black] Installing black package..."
  python -m pip install --upgrade black[jupyter]
fi
echo "[action-black] Black version: $(black --version)"

# Run black with reviewdog.
black_exit_val="0"
reviewdog_exit_val="0"
if [[ "${INPUT_REPORTER}" = 'github-pr-review' ]]; then
  echo "[action-black] Checking python code with the black formatter and reviewdog..."
  # shellcheck disable=SC2086
  black_check_output="$(black --diff --quiet --check . ${INPUT_BLACK_ARGS})" ||
    black_exit_val="$?"

  # Input black formatter output to reviewdog.
  # shellcheck disable=SC2086
  echo "${black_check_output}" | /tmp/reviewdog -f="diff" \
    -f.diff.strip=0 \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="github-pr-review" \
    -filter-mode="diff_context" \
    -level="${INPUT_LEVEL}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"

  # Re-generate black output. Needed because the output of the '--diff' option can not
  # be used to retrieve the files that black would change.
  # shellcheck disable=SC2086,SC2034
  black_check_output="$(black --check . ${INPUT_BLACK_ARGS} 2>&1)" || true
else
  echo "[action-black] Checking python code with the black formatter and reviewdog..."
  # shellcheck disable=SC2086
  black_check_output="$(black --check . ${INPUT_BLACK_ARGS} 2>&1)" ||
    black_exit_val="$?"

  # Input black formatter output to reviewdog.
  # shellcheck disable=SC2086
  echo "${black_check_output}" | /tmp/reviewdog -f="black" \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"
fi

# Print warning if no python files were found.
if [[ "${black_check_output}" == *"No Python files are present to be formatted. Nothing to do 😴"* ]]; then
  echo -e "\e[33m[action-black]: WARNING: No Python files are present to be formatted. Nothing to do 😴"
fi

# Print black output if verbose is true.
if [[ "${INPUT_VERBOSE}" = 'true' ]]; then
  echo "[action-black] Black output:"
  echo "${black_check_output}"
fi

# Retrieve formatted files from black output. Only add lines that start with 'would reformat'.
black_check_file_paths=()
while read -r line; do
  if [[ "${line}" == *"would reformat"* ]]; then
    black_check_file_paths+=("${line/"would reformat "/}")
  fi
done <<< "$black_check_output"

# Append the array elements to BLACK_CHECK_FILE_PATHS in github env.
# shellcheck disable=SC2129
echo "BLACK_CHECK_FILE_PATHS<<EOF" >> "$GITHUB_ENV"
echo "${black_check_file_paths[@]}" >> "$GITHUB_ENV"
echo "EOF" >> "$GITHUB_ENV"

# Throw error if an error occurred and fail_on_error is true.
if [[ "${INPUT_FAIL_ON_ERROR}" = 'true' && ("${black_exit_val}" -ne '0' ||
  "${reviewdog_exit_val}" -eq "1") ]]; then
  if [[ "${black_exit_val}" -eq "123" ]]; then
    # NOTE: Done since syntax errors are already handled by reviewdog (see
    # https://github.com/reviewdog/errorformat/commit/de0c436afead631a6e3a91ab3da71c16e69e2b9e)
    echo "[action-black] ERROR: Black found a syntax error when checking the" \
      "files (error code: ${black_exit_val})."
    if [[ "${reviewdog_exit_val}" -eq '1' ]]; then
      exit 1
    fi
  else
    exit 1
  fi
fi

echo "[action-black] Clean up reviewdog..."
rm /tmp/reviewdog
