# Black action

[![Test](https://github.com/rickstaa/action-black/workflows/Test/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/rickstaa/action-black/workflows/reviewdog/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/rickstaa/action-black/workflows/depup/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3Adepup)
[![release](https://github.com/rickstaa/action-black/workflows/release/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/rickstaa/action-black?logo=github\&sort=semver)](https://github.com/rickstaa/action-black/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github\&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

![github-pr-check demo](https://user-images.githubusercontent.com/17570430/102082175-c6773780-3e11-11eb-9af9-d7ee07ca353a.png)

This action runs the [black formatter](https://github.com/psf/black) with reviewdog on pull requests to improve code review experience. It can be used to format your code and/or annotate possible changes that would be made during this formatting.

## Inputs

```yaml
inputs:
  workdir:
    description: "Working directory relative to the root directory. Defaults to '.'."
    required: false
    default: "."
  format:
    description: |
      If true, black format files and commit are creatable (use other Action).
      Defaults to 'false'.
    required: false
    default: "false"
  fail_on_error:
    description: |
      Exit code when black formatting errors are found [true, false]. Defaults to 'false'.
    required: false
    default: "false"
  black_flags:
    description: "Additional black flags."
    required: false
    default: ""
  # Reviewdog related inputs
  annotate:
    description: "Annotate black changes using reviewdog. Defaults to 'true'."
    required: false
    default: "true"
  github_token:
    description: "The automatically created secret github action token."
    required: true
    default: ${{ github.token }}
  tool_name:
    description: "Tool name to use for reviewdog reporter. Defaults to 'black-format'."
    required: false
    default: "black-format"
  level:
    description: "Report level for reviewdog [info, warning, error]. Defaults to 'error'."
    required: false
    default: "error"
  reporter:
    description: |
      Reporter of reviewdog command [github-pr-check, github-pr-review, github-check].
      Defaults to 'github-pr-check'.
    required: false
    default: "github-pr-check"
  filter_mode:
    description: |
      Filtering mode for the reviewdog command [added, diff_context, file, nofilter].
      Default is added.
    required: false
    default: "added"
  reviewdog_flags:
    description: "Additional reviewdog flags."
    required: false
    default: ""
```

## Outputs

```yml
outputs:
  is_formatted:
    description: "Whether the files were formatted using the black formatter."
```

## Basic usage

In it's simplest form this action can be used to annotate the changes the black formatter would make if it was run on the code.

```yaml
name: reviewdog
on: [pull_request]
jobs:
  linter_name:
    name: runner / black formatter
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: reviewdog/action-black@v1
        with:
          github_token: ${{ secrets.github_token }}
          # Change reviewdog reporter if you need [github-pr-check, github-check].
          reporter: github-pr-check
          # Change reporter level if you need.
          # GitHub Status Check won't become failure with warning.
          level: warning
```

## Advanced use cases

This action can be combined with [peter-evans/create-pull-request](https://github.com/peter-evans/create-pull-request) or [stefanzweifel/git-auto-commit-action](https://github.com/stefanzweifel/git-auto-commit-action) to also apply the annotated changes to the repository.

### Commit changes

```yaml
name: reviewdog
on: [pull_request]
jobs:
  name: runner / black
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
      with:
        ref: ${{ github.head_ref }}
    - name: Check files using black formatter
      uses: reviewdog/action-black@v1
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        reporter: github-check
        level: error
        fail_on_error: true
        format: true
    - name: Commit black formatting results
      if: failure()
      uses: stefanzweifel/git-auto-commit-action@v4
      with:
        commit_message: ":art: Format Python code with psf/black push"
```

### Create pull request

```yaml
name: reviewdog
on: [pull_request]
jobs:
  name: runner / black
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - name: Check files using black formatter
      uses: reviewdog/action-black@v1
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        reporter: github-check
        level: error
        fail_on_error: true
        format: true
    - name: Create Pull Request
      if: failure()
      uses: peter-evans/create-pull-request@v3
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        title: "Format Python code with psf/black push"
        commit-message: ":art: Format Python code with psf/black"
        body: |
          There appear to be some python formatting errors in ${{ github.sha }}. This pull request
          uses the [psf/black](https://github.com/psf/black) formatter to fix these issues.
        branch: actions/black
```
