# Black action

[![Test](https://github.com/reviewdog/action-black/workflows/Test/badge.svg)](https://github.com/reviewdog/action-black/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/reviewdog/action-black/workflows/reviewdog/badge.svg)](https://github.com/reviewdog/action-black/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/reviewdog/action-black/workflows/depup/badge.svg)](https://github.com/reviewdog/action-black/actions?query=workflow%3Adepup)
[![release](https://github.com/reviewdog/action-black/workflows/release/badge.svg)](https://github.com/reviewdog/action-black/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/reviewdog/action-black?logo=github\&sort=semver)](https://github.com/reviewdog/action-black/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github\&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

![github-pr-check demo](https://user-images.githubusercontent.com/17570430/102082175-c6773780-3e11-11eb-9af9-d7ee07ca353a.png)

This action runs the [black formatter](https://github.com/psf/black) with reviewdog on pull requests to improve code review experience.

## Quick Start

In it's simplest form this action can be used to annotate the changes the [black](https://github.com/psf/black) formatter would make if it was run on the code.

```yaml
name: reviewdog
on: [pull_request]
jobs:
  linter_name:
    name: runner / black formatter
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: reviewdog/action-black@v2
        with:
          github_token: ${{ secrets.github_token }}
          # Change reviewdog reporter if you need [github-pr-check, github-check].
          reporter: github-pr-check
          # Change reporter level if you need.
          # GitHub Status Check won't become failure with a warning.
          level: warning
```

## Inputs

### `github_token`

**Required**. The [GITHUB_TOKEN](https://docs.github.com/en/free-pro-team@latest/actions/reference/authentication-in-a-workflow). Must be in form of `github_token: ${{ secrets.github_token }}`. Defaults to `${{ github.token }}`.

### `workdir`

**Optional**. The directory to run remark-lint in. Defaults to `.`.

#### `black_args`

**Optional**. Additional black input arguments. Defaults to `""`.

#### `black_version`

**Optional**. Version of black library `[black, black==23.0.1, black>=23.0.1, black[jupyter]]`. Defaults to `"black[jupyter]"`.

| :warning: | Because this action uses the black output to create the annotations, it does not work with the black `--quiet` flag. |
| --------- | -------------------------------------------------------------------------------------------------------------------- |

#### `tool_name`

**Optional**. Tool name to use for reviewdog reporter. Defaults to `remark-lint`.

### `level`

**Optional**. Report level for reviewdog `[info, warning, error]`. It's same as `-level` flag of reviewdog. Defaults to `error`.

### `reporter`

**Optional**. Reporter of reviewdog command `[github-pr-check, github-pr-review, github-check]`.
Default is github-pr-check.

### `filter_mode`

**Optional**. Filtering mode for the reviewdog command `[added, diff_context, file, nofilter]`. Defaults to `added`.

#### `fail_on_error`

**Optional**. Exit code for when reviewdog when errors are found `[true, false]`. Defaults to `false`.

### `reviewdog_flags`

**Optional**. Additional reviewdog flags. Defaults to `""`.

## Outputs

### `BLACK_CHECK_FILE_PATHS`

Contains all the files that would be changed by black.

## Format your code

This action is meant to annotate any possible changes that would need to be made to make your code adhere to the [black formatting guidelines](github.com/psf/black). It does not apply these changes to your codebase. If you also want to apply the changes to your repository, you can use the [reviewdog/action-suggester](https://github.com/reviewdog/action-suggester). You can find examples of how this is done can be found in [rickstaa/action-black](https://github.com/rickstaa/action-black/)
