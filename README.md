# Black action

[![Test](https://github.com/rickstaa/action-black/workflows/Test/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/rickstaa/action-black/workflows/reviewdog/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/rickstaa/action-black/workflows/depup/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3Adepup)
[![release](https://github.com/rickstaa/action-black/workflows/release/badge.svg)](https://github.com/rickstaa/action-black/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/rickstaa/action-black?logo=github&sort=semver)](https://github.com/rickstaa/action-black/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

![github-pr-check demo](https://user-images.githubusercontent.com/17570430/102082175-c6773780-3e11-11eb-9af9-d7ee07ca353a.png)

This action runs the [black formatter](https://github.com/psf/black) with reviewdog on pull requests to improve code review experience.

## Input

```yaml
inputs:
  workdir:
    description: "Working directory relative to the root directory."
    required: false
    default: "."
  # Reviewdog related inputs
  github_token:
    description: "The automatically created secret github action token."
    required: true
    default: ${{ github.token }}
  tool_name:
    description: "Tool name to use for reviewdog reporter"
    required: false
    default: "black-format"
  level:
    description: "Report level for reviewdog [info, warning, error]"
    required: false
    default: "error"
  reporter:
    description: |
      Reporter of reviewdog command [github-pr-check, github-pr-review, github-check].
      Default is github-pr-check. Github-pr-review is not supported for the black formatter.
    required: false
    default: "github-pr-check"
  filter_mode:
    description: |
      Filtering mode for the reviewdog command [added, diff_context, file, nofilter].
      Default is added.
    required: false
    default: "added"
  fail_on_error:
    description: |
      Exit code for reviewdog when errors are found [true,false]
      Default is `false`.
    required: false
    default: "false"
  reviewdog_flags:
    description: "Additional reviewdog flags"
    required: false
    default: ""
```

**NOTE:** The reviewdog [github-pr-review](https://github.com/reviewdog/reviewdog#reporter-github-pullrequest-review-comment--reportergithub-pr-review) option is not supported as the black formatter does not specify line numbers.

## Usage

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
          reporter: github-pr-review
          # Change reporter level if you need.
          # GitHub Status Check won't become failure with warning.
          level: warning
```

## Development

### Release

#### [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr)

You can bump version on merging Pull Requests with specific labels (bump:major,bump:minor,bump:patch).
Pushing tag manually by yourself also work.

#### [haya14busa/action-update-semver](https://github.com/haya14busa/action-update-semver)

This action updates major/minor release tags on a tag push. e.g. Update v1 and v1.2 tag when released v1.2.3.
ref: <https://help.github.com/en/articles/about-actions#versioning-your-action>

### Lint - reviewdog integration

This reviewdog action template itself is integrated with reviewdog to run lints
which is useful for Docker container based actions.

![reviewdog integration](https://user-images.githubusercontent.com/3797062/72735107-7fbb9600-3bde-11ea-8087-12af76e7ee6f.png)

Supported linters:

-   [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)
-   [reviewdog/action-hadolint](https://github.com/reviewdog/action-hadolint)
-   [reviewdog/action-misspell](https://github.com/reviewdog/action-misspell)

### Dependencies Update Automation

This repository uses [haya14busa/action-depup](https://github.com/haya14busa/action-depup) to update
reviewdog version.

[![reviewdog depup demo](https://user-images.githubusercontent.com/3797062/73154254-170e7500-411a-11ea-8211-912e9de7c936.png)](https://github.com/rickstaa/action-black/pull/6)
