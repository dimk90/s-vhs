#!/bin/bash
#
# Release s-vhs from develop to master and GitHub.
#
# Prepare the version bump, dated changelog, completed-plan removal, pinned
# remote imports, README, and rendered examples before running this script. The
# prepared tree may be uncommitted or already committed and pushed to develop.
# The script performs its checks before publishing anything, asks for one
# approval, and stops on the first failed release step without attempting
# rollback.
#

set -uo pipefail

readonly _RELEASE_PROJECT_NAME='s-vhs'
readonly _RELEASE_GITHUB_REPOSITORY='dimk90/s-vhs'
readonly _RELEASE_PAGES_BASE_URL='https://dimk90.github.io/s-vhs'
readonly _RELEASE_DEVELOP_BRANCH='develop'
readonly _RELEASE_MASTER_BRANCH='master'
readonly _RELEASE_PUBLICATION_ATTEMPTS=90
readonly _RELEASE_PUBLICATION_INTERVAL=10
readonly _RELEASE_ALLOWED_PATHS=(
    CHANGELOG.md
    doc/DEBUG.md
    doc/PLAN.md
    README.md
    s-vhs.sh
    examples/remote-import.rec.sh
)
readonly _RELEASE_REMOTE_IMPORT_FILES=(
    README.md
    doc/DEBUG.md
    examples/remote-import.rec.sh
)

_RELEASE_BLOCKERS=()
_RELEASE_CANDIDATE_PATHS=()
_RELEASE_CANDIDATE_MODE='invalid'
_RELEASE_TMP_DIR=''
_RELEASE_LOG_FILE=''
_RELEASE_TARGET_VERSION=''
_RELEASE_TARGET_TAG=''
_RELEASE_LATEST_VERSION=''
_RELEASE_APPROVED_HEAD=''
_RELEASE_APPROVED_STATUS=''
_RELEASE_RELEASE_COMMIT=''
_RELEASE_MERGE_COMMIT=''
_RELEASE_STEP_NUMBER=0
_RELEASE_DEVELOP_PUSHED='not pushed'
_RELEASE_TAG_PUSHED='not pushed'
_RELEASE_GITHUB_STATE='not observed'


## Main

main() {
    #
    # Validate and apply the prepared release.
    #
    # Parameters:
    #   $@ - command-line arguments; none are accepted.
    #
    # Example:
    #   main
    #
    _release_require_environment ${@+"$@"}
    _release_prepare_workspace

    _release_run_sanity_checks
    _release_confirm_release_plan

    _release_validate_release_tree
    _release_commit_release
    _release_push_develop
    _release_merge_into_master
    _release_tag_master
    _release_push_master_and_tag
    _release_wait_for_publication
    _release_return_to_develop
    _release_report_success
}


## Internal

# Bash cannot hide these functions; the _release_ prefix marks the private
# boundary and avoids collisions if the script is ever sourced accidentally.


### Startup

_release_require_environment() {
    #
    # Exit unless the script was invoked without arguments, every required
    # command exists, and the terminal is interactive.
    #
    # Parameters:
    #   $@ - command-line arguments; none are accepted.
    #
    # Example:
    #   _release_require_environment "$@"
    #
    local argument_count=$#
    local missing_tools=()
    local tool

    if ((argument_count > 0)); then
        printf 'Usage: %s\n' "$0" >&2
        printf 'Releases the version already prepared in s-vhs.sh and CHANGELOG.md.\n' >&2
        exit 2
    fi

    for tool in curl git gum shellcheck; do
        command -v "$tool" >/dev/null 2>&1 || missing_tools+=("$tool")
    done
    if ((${#missing_tools[@]} > 0)); then
        printf 'Missing required command(s): %s\n' "${missing_tools[*]}" >&2
        exit 1
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        printf 'The release script needs an interactive terminal.\n' >&2
        exit 1
    fi
}


_release_prepare_workspace() {
    #
    # Enter the repository root and create the temporary command log removed by
    # the exit trap.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_prepare_workspace
    #
    local repository_root

    repository_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ -z $repository_root ]]; then
        printf 'Run this script inside the %s repository.\n' "$_RELEASE_PROJECT_NAME" >&2
        exit 1
    fi
    cd "$repository_root" || exit 1

    _RELEASE_TMP_DIR="$(mktemp -d -t s-vhs-release-XXXXXX)" || exit 1
    readonly _RELEASE_TMP_DIR
    _RELEASE_LOG_FILE="${_RELEASE_TMP_DIR}/command.log"
    readonly _RELEASE_LOG_FILE
    trap 'rm -rf "$_RELEASE_TMP_DIR"' EXIT
}


### Sanity checks

_release_run_sanity_checks() {
    #
    # Run every sanity check, then exit when any of them recorded a blocker.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_run_sanity_checks
    #
    _release_heading "Sanity checks for ${_RELEASE_PROJECT_NAME}"

    _release_check_required_files
    _release_check_origin_remote
    _release_check_repository_state
    _release_check_candidate_paths
    if _release_read_target_version; then
        _release_check_changelog
        _release_check_plan
        _release_check_remote_imports
    fi
    _release_check_origin_state
    _release_report_blockers
}


_release_check_required_files() {
    #
    # Block when a file the release depends on is missing.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_required_files
    #
    local required_file

    for required_file in \
        .github/workflows/release.yml \
        CHANGELOG.md \
        doc/PLAN.md \
        doc/RELEASE.md \
        README.md \
        s-vhs.sh \
        scripts/release.sh \
        examples/remote-import.rec.sh
    do
        if [[ -f $required_file ]]; then
            _release_pass "found ${required_file}"
        else
            _release_block "required release file is missing: ${required_file}"
        fi
    done
}


_release_check_origin_remote() {
    #
    # Block when origin does not identify the expected GitHub repository.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_origin_remote
    #
    local origin_url origin_pattern

    origin_url="$(git remote get-url origin 2>/dev/null)"
    origin_pattern='^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)dimk90/s-vhs(\.git)?$'
    if [[ $origin_url =~ $origin_pattern ]]; then
        _release_pass "origin identifies ${_RELEASE_GITHUB_REPOSITORY}"
    else
        _release_block 'origin does not identify the expected GitHub repository' \
                       "${origin_url:-origin is missing}"
    fi
}


_release_check_repository_state() {
    #
    # Block unless the release starts on develop with no Git operation running.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_repository_state
    #
    local operations=()
    local current_branch git_dir marker

    current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
    if [[ $current_branch == "$_RELEASE_DEVELOP_BRANCH" ]]; then
        _release_pass "current branch is ${_RELEASE_DEVELOP_BRANCH}"
    else
        _release_block "release must start on ${_RELEASE_DEVELOP_BRANCH}" \
                       "current branch: ${current_branch:-detached HEAD}"
    fi

    git_dir="$(git rev-parse --absolute-git-dir)"
    for marker in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG rebase-apply rebase-merge; do
        [[ -e ${git_dir}/${marker} ]] && operations+=("$marker")
    done
    if ((${#operations[@]} == 0)); then
        _release_pass 'no merge, rebase, cherry-pick, revert, or bisect is in progress'
    else
        _release_block 'a Git operation is in progress' \
                       "$(printf '%s\n' ${operations[@]+"${operations[@]}"})"
    fi
}


_release_check_candidate_paths() {
    #
    # Classify the candidate as a worktree or committed change set and block
    # when the worktree holds anything outside the release paths.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_candidate_paths
    #
    local unexpected_paths=()
    local path

    while IFS= read -r -d '' path; do
        _RELEASE_CANDIDATE_PATHS+=("$path")
        _release_is_allowed_path "$path" || unexpected_paths+=("$path")
    done < <(git diff HEAD --name-only -z
             git ls-files --others --exclude-standard -z)

    if ((${#_RELEASE_CANDIDATE_PATHS[@]} == 0)); then
        _RELEASE_CANDIDATE_MODE='committed'
        _release_pass 'the worktree is clean; checking the committed develop tree'
    elif ((${#unexpected_paths[@]} > 0)); then
        _release_block 'the worktree holds changes outside the release paths' \
                       "$(printf '%s\n' ${unexpected_paths[@]+"${unexpected_paths[@]}"})"
    else
        _RELEASE_CANDIDATE_MODE='worktree'
        _release_pass "the worktree holds ${#_RELEASE_CANDIDATE_PATHS[@]} release path(s) and nothing else"
        _release_check_required_candidates 'the prepared release' '' \
            ${_RELEASE_CANDIDATE_PATHS[@]+"${_RELEASE_CANDIDATE_PATHS[@]}"}
    fi
}


_release_check_required_candidates() {
    #
    # Block when a candidate change set leaves CHANGELOG.md or s-vhs.sh
    # untouched.
    #
    # Parameters:
    #   $1 - subject - candidate description used in the blocker message.
    #   $2 - scope - (optional) - comparison named in the blocker message,
    #        such as 'from origin/master'.
    #   $3... - paths - candidate paths to search.
    #
    # Example:
    #   _release_check_required_candidates 'the prepared release' '' 'CHANGELOG.md'
    #
    local subject="$1"
    local scope="$2"
    shift 2
    local paths=()
    local required_candidate path candidate_found

    (($# == 0)) || paths=("$@")
    for required_candidate in CHANGELOG.md s-vhs.sh; do
        candidate_found=false
        for path in ${paths[@]+"${paths[@]}"}; do
            if [[ $path == "$required_candidate" ]]; then
                candidate_found=true
                break
            fi
        done
        if [[ $candidate_found != true ]]; then
            _release_block "${subject} does not change ${required_candidate}${scope:+ ${scope}}"
        fi
    done
}


_release_read_target_version() {
    #
    # Read the prepared version through svhs_version and derive the release tag.
    #
    # Returns nonzero when s-vhs.sh cannot supply a stable version, so the
    # caller can skip every check that depends on it.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_read_target_version && _release_check_changelog
    #
    if ! _release_capture 'reading svhs_version' \
                          bash -c 'source ./s-vhs.sh; svhs_version'; then
        _release_block 'unable to read svhs_version' "$(tail -n 10 "$_RELEASE_LOG_FILE")"
        return 1
    fi

    _RELEASE_TARGET_VERSION="$(tr -d '\r\n' <"$_RELEASE_LOG_FILE")"
    if [[ ! $_RELEASE_TARGET_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        _release_block 'svhs_version must use stable X.Y.Z form' \
                       "found: ${_RELEASE_TARGET_VERSION:-missing}"
        return 1
    fi

    _RELEASE_TARGET_TAG="v${_RELEASE_TARGET_VERSION}"
    _release_pass "svhs_version reports ${_RELEASE_TARGET_VERSION}"
    return 0
}


_release_check_changelog() {
    #
    # Block unless the newest nonempty CHANGELOG.md section dates the target
    # version exactly once.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_changelog
    #
    local changelog_pattern changelog_heading changelog_version release_date
    local target_changelog_heading target_heading_count

    # Literal regex: $ anchors the heading and must not expand
    # shellcheck disable=SC2016
    changelog_pattern='^## `\[v([0-9]+\.[0-9]+\.[0-9]+)\]` - (.+)$'
    changelog_heading="$(grep -m 1 -E '^## `\[v[0-9]' CHANGELOG.md)"
    if [[ ! $changelog_heading =~ $changelog_pattern ]]; then
        _release_block 'unable to parse the latest CHANGELOG.md version heading' \
                       "${changelog_heading:-no version heading found}"
        return 0
    fi

    changelog_version="${BASH_REMATCH[1]}"
    release_date="${BASH_REMATCH[2]}"
    if [[ $changelog_version == "$_RELEASE_TARGET_VERSION" ]]; then
        _release_pass 'svhs_version matches the latest CHANGELOG.md version'
    else
        _release_block 'svhs_version and CHANGELOG.md versions differ' \
                       "s-vhs.sh: ${_RELEASE_TARGET_VERSION}; CHANGELOG.md: ${changelog_version}"
    fi
    if [[ $release_date =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$ ]]; then
        _release_pass "CHANGELOG.md dates v${changelog_version} as ${release_date}"
    else
        _release_block "CHANGELOG.md has no DD.MM.YYYY date for v${changelog_version}" \
                       "found: ${release_date}"
    fi

    target_changelog_heading="$(grep -m 1 -F "## \`[${_RELEASE_TARGET_TAG}]\` - " CHANGELOG.md)"
    target_heading_count="$(grep -c -F "## \`[${_RELEASE_TARGET_TAG}]\` - " CHANGELOG.md)"
    if [[ $target_heading_count == 1 ]]; then
        _release_pass "CHANGELOG.md contains one ${_RELEASE_TARGET_TAG} heading"
        if _release_changelog_has_notes "$target_changelog_heading"; then
            _release_pass "CHANGELOG.md has release notes for ${_RELEASE_TARGET_TAG}"
        else
            _release_block "CHANGELOG.md has no release notes for ${_RELEASE_TARGET_TAG}"
        fi
    else
        _release_block "CHANGELOG.md must contain exactly one ${_RELEASE_TARGET_TAG} heading" \
                       "found: ${target_heading_count}"
    fi
}


_release_changelog_has_notes() {
    #
    # Determine whether a changelog heading is followed by nonblank content
    # before the next version heading.
    #
    # Parameters:
    #   $1 - heading - exact version heading whose section should be checked.
    #
    # Example:
    #   _release_changelog_has_notes '## `[v0.3.0]` - 13.08.2026'
    #
    local heading="$1"
    local line
    local in_section=false

    while IFS= read -r line; do
        if [[ $in_section == false ]]; then
            [[ $line == "$heading" ]] && in_section=true
            continue
        fi
        [[ $line == '## '* ]] && break
        [[ $line =~ [^[:space:]] ]] && return 0
    done < CHANGELOG.md

    return 1
}


_release_check_plan() {
    #
    # Block while doc/PLAN.md still plans the version being released.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_plan
    #
    local plan_pattern

    plan_pattern="^## v${_RELEASE_TARGET_VERSION//./\\.}[[:space:]]*$"
    if grep -qE "$plan_pattern" doc/PLAN.md; then
        _release_block "doc/PLAN.md still contains v${_RELEASE_TARGET_VERSION}"
    else
        _release_pass "doc/PLAN.md does not contain v${_RELEASE_TARGET_VERSION}"
    fi
}


_release_check_remote_imports() {
    #
    # Block unless every release-pinned remote import names the target tag.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_remote_imports
    #
    local stale_urls=()
    local file url
    local url_count

    for file in ${_RELEASE_REMOTE_IMPORT_FILES[@]+"${_RELEASE_REMOTE_IMPORT_FILES[@]}"}; do
        stale_urls=()
        url_count=0
        while IFS= read -r url; do
            url_count=$((url_count + 1))
            [[ ${url##*/} == "$_RELEASE_TARGET_TAG" ]] || stale_urls+=("$url")
        done < <(grep -Eo \
            'https://dimk90\.github\.io/s-vhs/v[0-9]+\.[0-9]+\.[0-9]+' "$file")

        if ((url_count == 0)); then
            _release_block "${file} contains no pinned remote import"
        elif ((${#stale_urls[@]} > 0)); then
            _release_block "${file} contains a remote import not pinned to ${_RELEASE_TARGET_TAG}" \
                           "$(printf '%s\n' ${stale_urls[@]+"${stale_urls[@]}"})"
        else
            _release_pass "${file} pins ${url_count} remote import(s) to ${_RELEASE_TARGET_TAG}"
        fi
    done
}


_release_check_origin_state() {
    #
    # Fetch origin and block on any branch, tree, tag, or publication state the
    # release cannot start from.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_origin_state
    #
    if ! git fetch --quiet --prune --tags origin; then
        _release_block 'unable to fetch origin'
        return 0
    fi

    _release_pass 'fetched origin branches and tags'
    _release_check_branch_synchronization
    if [[ $_RELEASE_CANDIDATE_MODE == 'committed' ]]; then
        _release_check_committed_candidate
    fi
    _release_check_master_ancestry
    _release_check_version_order
    _release_check_target_tag
    _release_check_deploy_branch
    _release_check_target_publication
}


_release_check_branch_synchronization() {
    #
    # Block unless develop and master exactly match their origin branches.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_branch_synchronization
    #
    local branch counts ahead behind

    for branch in "$_RELEASE_DEVELOP_BRANCH" "$_RELEASE_MASTER_BRANCH"; do
        if ! git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null ||
           ! git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null; then
            _release_block "local or origin branch is missing: ${branch}"
            continue
        fi

        if ! counts="$(git rev-list --left-right --count \
                            "refs/heads/${branch}...refs/remotes/origin/${branch}")"; then
            _release_block "unable to compare ${branch} with origin/${branch}"
            continue
        fi
        read -r ahead behind <<< "$counts"
        if ((behind > 0)); then
            _release_block "${branch} is behind origin/${branch}" \
                           "ahead ${ahead}, behind ${behind}"
        elif ((ahead > 0)); then
            _release_block "${branch} is ahead of origin/${branch}" \
                           'both branches must match origin before the release starts'
        else
            _release_pass "${branch} exactly matches origin/${branch}"
        fi
    done
}


_release_check_committed_candidate() {
    #
    # Block unless the committed develop tree carries a release change set
    # against origin/master.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_committed_candidate
    #
    local committed_candidate_paths=()
    local path

    while IFS= read -r -d '' path; do
        committed_candidate_paths+=("$path")
    done < <(git diff --name-only -z \
                      "refs/remotes/origin/${_RELEASE_MASTER_BRANCH}" \
                      "refs/heads/${_RELEASE_DEVELOP_BRANCH}")

    if ((${#committed_candidate_paths[@]} == 0)); then
        _release_block 'the committed develop tree has no changes from origin/master'
    else
        _release_pass \
            "the committed develop tree differs from origin/master in ${#committed_candidate_paths[@]} path(s)"
    fi
    _release_check_required_candidates 'the committed release' 'from origin/master' \
        ${committed_candidate_paths[@]+"${committed_candidate_paths[@]}"}
}


_release_check_master_ancestry() {
    #
    # Block when origin/master carries tree changes that develop does not have.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_master_ancestry
    #
    local merge_base

    merge_base="$(git merge-base "refs/remotes/origin/${_RELEASE_MASTER_BRANCH}" \
                                  "refs/heads/${_RELEASE_DEVELOP_BRANCH}" 2>/dev/null)"
    if [[ -n $merge_base ]] &&
       git diff --quiet "$merge_base" "refs/remotes/origin/${_RELEASE_MASTER_BRANCH}"; then
        _release_pass 'origin/master has no tree changes absent from develop'
    else
        _release_block 'origin/master contains tree changes absent from develop'
    fi
}


_release_check_version_order() {
    #
    # Block unless the target version is newer than every stable Git tag.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_version_order
    #
    local latest_version=''
    local tag version

    [[ -n $_RELEASE_TARGET_VERSION ]] || return 0

    while IFS= read -r tag; do
        [[ $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
        version="${tag#v}"
        if [[ -z $latest_version ]] || _release_version_is_newer "$version" "$latest_version"; then
            latest_version="$version"
        fi
    done < <(git tag --list)

    _RELEASE_LATEST_VERSION="$latest_version"
    if [[ -z $latest_version ]]; then
        _release_pass "${_RELEASE_TARGET_TAG} will be the first stable tag"
    elif _release_version_is_newer "$_RELEASE_TARGET_VERSION" "$latest_version"; then
        _release_pass "target is newer than v${latest_version}"
    else
        _release_block "${_RELEASE_TARGET_TAG} is not newer than v${latest_version}"
    fi
}


_release_check_target_tag() {
    #
    # Block when the target tag already exists locally or on origin.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_target_tag
    #
    local remote_tag

    [[ -n $_RELEASE_TARGET_TAG ]] || return 0

    if git show-ref --verify --quiet "refs/tags/${_RELEASE_TARGET_TAG}"; then
        _release_block "local tag already exists: ${_RELEASE_TARGET_TAG}"
    else
        _release_pass "local tag is absent: ${_RELEASE_TARGET_TAG}"
    fi

    if remote_tag="$(git ls-remote --tags origin "refs/tags/${_RELEASE_TARGET_TAG}")"; then
        if [[ -n $remote_tag ]]; then
            _release_block "origin tag already exists: ${_RELEASE_TARGET_TAG}" "$remote_tag"
        else
            _release_pass "origin tag is absent: ${_RELEASE_TARGET_TAG}"
        fi
    else
        _release_block "unable to check origin tag ${_RELEASE_TARGET_TAG}"
    fi
}


_release_check_deploy_branch() {
    #
    # Block when the remote branch required by the release workflow is absent.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_deploy_branch
    #
    if git rev-parse --verify --quiet 'refs/remotes/origin/deploy' >/dev/null; then
        _release_pass 'origin/deploy is available for Pages publication'
    else
        _release_block 'origin/deploy is missing; the release workflow cannot publish Pages'
    fi
}


_release_check_target_publication() {
    #
    # Block when GitHub or Pages already publishes the target version.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_check_target_publication
    #
    local release_url pages_url

    [[ -n $_RELEASE_TARGET_TAG ]] || return 0

    release_url="https://github.com/${_RELEASE_GITHUB_REPOSITORY}/releases/tag/${_RELEASE_TARGET_TAG}"
    pages_url="${_RELEASE_PAGES_BASE_URL}/${_RELEASE_TARGET_TAG}"
    _release_check_unpublished_url 'GitHub release' "$release_url"
    _release_check_unpublished_url 'versioned Pages file' "$pages_url"
}


_release_check_unpublished_url() {
    #
    # Block unless an HTTP URL returns 404 before publication.
    #
    # Parameters:
    #   $1 - label - artifact described in check output.
    #   $2 - url - public artifact URL.
    #
    # Example:
    #   _release_check_unpublished_url 'GitHub release' "$release_url"
    #
    local label="$1"
    local url="$2"
    local status

    if ! status="$(_release_http_status "$url" 2>"$_RELEASE_LOG_FILE")"; then
        _release_block "unable to check the target ${label}" \
                       "$(tail -n 10 "$_RELEASE_LOG_FILE")"
        return 0
    fi

    case "$status" in
        404) _release_pass "target ${label} is absent" ;;
        200) _release_block "target ${label} already exists" "$url" ;;
        *)   _release_block "unable to confirm that the target ${label} is absent" \
                            "HTTP ${status}: ${url}" ;;
    esac
}


_release_report_blockers() {
    #
    # Print every recorded blocker and exit before the release starts.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_report_blockers
    #
    local blocker

    ((${#_RELEASE_BLOCKERS[@]} > 0)) || return 0

    _release_heading "${#_RELEASE_BLOCKERS[@]} blocker(s): release did not start"
    for blocker in ${_RELEASE_BLOCKERS[@]+"${_RELEASE_BLOCKERS[@]}"}; do
        printf '  %s\n' "$blocker"
    done
    printf '\n'
    _release_info 'nothing was staged, committed, tagged, pushed, or published'
    exit 1
}


### Approval

_release_confirm_release_plan() {
    #
    # Freeze the approved candidate, present the plan, and require one explicit
    # approval of an unchanged candidate.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_confirm_release_plan
    #
    _RELEASE_APPROVED_HEAD="$(git rev-parse HEAD)"
    _RELEASE_APPROVED_STATUS="$(git status --porcelain=v1 --untracked-files=all)"
    readonly _RELEASE_APPROVED_HEAD _RELEASE_APPROVED_STATUS

    _release_print_release_plan

    if ! gum confirm "Release ${_RELEASE_PROJECT_NAME} ${_RELEASE_TARGET_TAG}?" \
                     --affirmative='Release' --negative='Cancel'; then
        _release_info 'release cancelled; nothing was changed'
        exit 1
    fi

    if ! _release_candidate_is_approved; then
        _release_stop 'the candidate changed after approval; run the preflight again'
    fi
}


_release_print_release_plan() {
    #
    # Print the release summary, numbered plan, and approval scope.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_print_release_plan
    #
    local summary_lines=()
    local plan_lines=()
    local candidate_summary candidate_plan previous_version

    if [[ $_RELEASE_CANDIDATE_MODE == 'committed' ]]; then
        candidate_summary="$(git rev-parse --short HEAD) (already committed on develop)"
        candidate_plan=' 2. Use the reviewed release tree already committed on develop'
    else
        candidate_summary="uncommitted: ${_RELEASE_CANDIDATE_PATHS[*]-}"
        candidate_plan=" 2. Commit reviewed release paths as [doc] Release ${_RELEASE_TARGET_TAG}"
    fi
    previous_version="${_RELEASE_LATEST_VERSION:+v${_RELEASE_LATEST_VERSION}}"
    previous_version="${previous_version:-none}"

    _release_heading "Release plan for ${_RELEASE_TARGET_TAG}"
    summary_lines=(
        "project      ${_RELEASE_PROJECT_NAME}"
        "version      ${_RELEASE_TARGET_VERSION} (previous: ${previous_version})"
        "tag          ${_RELEASE_TARGET_TAG}"
        "branches     ${_RELEASE_DEVELOP_BRANCH} → ${_RELEASE_MASTER_BRANCH}"
        "publication  GitHub release + versioned/latest Pages files"
        "candidate    ${candidate_summary}"
    )
    gum style --border rounded --border-foreground 212 --padding '0 2' --margin '1 0 0 0' -- \
              ${summary_lines[@]+"${summary_lines[@]}"}

    plan_lines=(
        ' 1. Validate: diff, ShellCheck, Bash syntax, scaffold, README template'
        "$candidate_plan"
        ' 3. Push develop to origin and verify the remote commit'
        ' 4. Update master, merge develop with --no-ff, and revalidate the exact tree'
        " 5. Verify version and clean state, then tag ${_RELEASE_TARGET_TAG}"
        ' 6. Atomically push master and only the target tag (starts the release workflow)'
        ' 7. Wait for the GitHub release and verify versioned/latest Pages imports'
        ' 8. Return to develop and verify a clean worktree'
    )
    gum style --border rounded --border-foreground 244 --padding '0 2' --margin '1 0 0 0' -- \
              ${plan_lines[@]+"${plan_lines[@]}"}

    gum style --faint --margin '1 0 1 2' -- \
              'Approval also confirms the changelog text, README and pinned imports,' \
              'recording scripts, and rendered examples were reviewed as required by doc/RELEASE.md.'
}


_release_candidate_is_approved() {
    #
    # Determine whether HEAD and the complete worktree still match the state
    # frozen for approval.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_candidate_is_approved || exit 1
    #
    local current_head current_status

    current_head="$(git rev-parse HEAD)"
    current_status="$(git status --porcelain=v1 --untracked-files=all)"
    [[ $current_head == "$_RELEASE_APPROVED_HEAD" &&
       $current_status == "$_RELEASE_APPROVED_STATUS" ]] || return 1
    return 0
}


### Release steps

_release_validate_release_tree() {
    #
    # Inspect and check the approved candidate before anything leaves the
    # machine.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_validate_release_tree
    #
    _release_begin_step 'Validate the release tree'
    if [[ $_RELEASE_CANDIDATE_MODE == 'committed' ]]; then
        _release_apply_command 'checking the committed candidate diff' \
                               git diff --check \
                                   "refs/remotes/origin/${_RELEASE_MASTER_BRANCH}" \
                                   "refs/heads/${_RELEASE_DEVELOP_BRANCH}"
    else
        _release_apply_command 'checking the candidate diff' git diff --check
    fi
    _release_run_project_checks
}


_release_run_project_checks() {
    #
    # Run static checks and verify the generated recording template against its
    # README copy.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_run_project_checks
    #
    local shell_paths=(s-vhs.sh scripts/release.sh)
    local shell_path

    for shell_path in examples/*.rec.sh; do
        shell_paths+=("$shell_path")
    done

    _release_apply_command 'running ShellCheck' shellcheck s-vhs.sh scripts/release.sh
    _release_apply_command 'checking Bash syntax' \
                           bash -n ${shell_paths[@]+"${shell_paths[@]}"}
    _release_validate_template
}


_release_validate_template() {
    #
    # Generate the recording scaffold, check its syntax, and require its exact
    # copy in README.md.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_validate_template
    #
    local generated_template="${_RELEASE_TMP_DIR}/template.rec.sh"
    local readme_template="${_RELEASE_TMP_DIR}/readme-template.rec.sh"
    local template_diff

    rm -f -- "$generated_template" "$readme_template"
    _release_apply_command 'generating the recording scaffold' \
                           ./s-vhs.sh new "$generated_template"
    _release_apply_command 'checking the recording scaffold syntax' \
                           bash -n "$generated_template"

    if ! _release_extract_readme_template README.md >"$readme_template"; then
        _release_stop 'unable to extract the recording template from README.md'
    fi
    if cmp -s "$generated_template" "$readme_template"; then
        _release_pass 'README.md contains the exact generated recording template'
        return 0
    fi

    template_diff="$(diff -u "$generated_template" "$readme_template")"
    _release_stop 'README.md recording template differs from s-vhs.sh' "$template_diff"
}


_release_extract_readme_template() {
    #
    # Print the Bash code block immediately following README.md's "It writes:"
    # marker.
    #
    # Parameters:
    #   $1 - readme - README file to inspect.
    #
    # Example:
    #   _release_extract_readme_template README.md > "$template"
    #
    local readme="$1"
    local line
    local marker_found=false
    local fence_found=false

    while IFS= read -r line; do
        if [[ $marker_found == false ]]; then
            [[ $line == 'It writes:' ]] && marker_found=true
            continue
        fi
        if [[ $fence_found == false ]]; then
            [[ $line == '```bash' ]] && fence_found=true
            continue
        fi
        [[ $line == '```' ]] && return 0
        printf '%s\n' "$line"
    done < "$readme"

    return 1
}


_release_commit_release() {
    #
    # Establish the release commit on develop from the unchanged approved
    # candidate.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_commit_release
    #
    if ! _release_candidate_is_approved; then
        _release_stop 'the candidate changed during validation; run the preflight again'
    fi

    if [[ $_RELEASE_CANDIDATE_MODE == 'committed' ]]; then
        _release_use_committed_release
    else
        _release_create_release_commit
    fi
}


_release_use_committed_release() {
    #
    # Adopt the reviewed commit already on develop as the release commit.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_use_committed_release
    #
    _release_begin_step 'Use the committed release on develop'
    if [[ $(git rev-parse HEAD) != "$_RELEASE_APPROVED_HEAD" ]]; then
        _release_stop 'develop moved while validating the committed release'
    fi
    if [[ -n $(git status --porcelain) ]]; then
        _release_stop 'the committed release worktree is no longer clean' \
                      "$(git status --short)"
    fi
    _RELEASE_RELEASE_COMMIT="$_RELEASE_APPROVED_HEAD"
    _release_pass "release commit: $(git log -1 --format='%h %s')"
}


_release_create_release_commit() {
    #
    # Stage exactly the approved paths and commit them on develop.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_create_release_commit
    #
    local expected_paths staged_paths commit_message

    _release_begin_step 'Commit the release on develop'
    if ! git add -- ${_RELEASE_CANDIDATE_PATHS[@]+"${_RELEASE_CANDIDATE_PATHS[@]}"}; then
        _release_stop 'unable to stage the reviewed release paths'
    fi
    if ! git diff --quiet || [[ -n $(git ls-files --others --exclude-standard) ]]; then
        _release_stop 'unstaged or untracked changes appeared after staging' \
                      "$(git status --short)"
    fi
    expected_paths="$(printf '%s\n' \
        ${_RELEASE_CANDIDATE_PATHS[@]+"${_RELEASE_CANDIDATE_PATHS[@]}"} | sort)"
    staged_paths="$(git diff --cached --name-only | sort)"
    if [[ $staged_paths != "$expected_paths" ]]; then
        _release_stop 'the staged paths differ from the approved release paths' \
                      "$(git status --short)"
    fi
    commit_message="[doc] Release ${_RELEASE_TARGET_TAG}"
    if ! git commit -m "$commit_message"; then
        _release_stop 'release commit failed'
    fi
    if [[ -n $(git status --porcelain) ]]; then
        _release_stop 'the worktree is not clean after the release commit' \
                      "$(git status --short)"
    fi
    _RELEASE_RELEASE_COMMIT="$(git rev-parse HEAD)"
    _release_pass "release commit: $(git log -1 --format='%h %s')"
}


_release_push_develop() {
    #
    # Push the release commit to origin/develop and verify the remote ref.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_push_develop
    #
    local develop_push_status remote_develop

    _release_begin_step 'Push develop to origin'
    develop_push_status=0
    git push origin "$_RELEASE_DEVELOP_BRANCH" || develop_push_status=$?
    remote_develop="$(git ls-remote origin "refs/heads/${_RELEASE_DEVELOP_BRANCH}" | awk '{ print $1 }')"
    if [[ $remote_develop == "$_RELEASE_RELEASE_COMMIT" ]]; then
        _RELEASE_DEVELOP_PUSHED="verified at ${_RELEASE_RELEASE_COMMIT:0:12}"
    else
        _RELEASE_DEVELOP_PUSHED='not verified'
    fi
    if ((develop_push_status != 0)); then
        _release_stop "git push origin develop exited ${develop_push_status}" \
                      "origin: ${remote_develop:-unknown}; expected: ${_RELEASE_RELEASE_COMMIT}"
    fi
    if [[ $remote_develop != "$_RELEASE_RELEASE_COMMIT" ]]; then
        _release_stop 'origin/develop does not identify the release commit' \
                      "origin: ${remote_develop:-unknown}; expected: ${_RELEASE_RELEASE_COMMIT}"
    fi
    _release_pass "origin/develop identifies ${_RELEASE_RELEASE_COMMIT:0:12}"
}


_release_merge_into_master() {
    #
    # Merge develop into master with --no-ff and revalidate the merged tree.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_merge_into_master
    #
    local master_parent first_parent second_parent

    _release_begin_step 'Merge develop into master and revalidate'
    if ! git switch "$_RELEASE_MASTER_BRANCH"; then
        _release_stop 'unable to switch to master'
    fi
    if ! git pull --ff-only origin "$_RELEASE_MASTER_BRANCH"; then
        _release_stop 'master cannot fast-forward to origin/master'
    fi
    master_parent="$(git rev-parse HEAD)"
    if ! git merge --no-ff --no-edit "$_RELEASE_DEVELOP_BRANCH"; then
        _release_stop 'develop could not be merged into master'
    fi
    _RELEASE_MERGE_COMMIT="$(git rev-parse HEAD)"
    first_parent="$(git rev-parse --verify --quiet 'HEAD^1')"
    second_parent="$(git rev-parse --verify --quiet 'HEAD^2')"
    if [[ $first_parent != "$master_parent" || $second_parent != "$_RELEASE_RELEASE_COMMIT" ]]; then
        _release_stop 'the merge parents do not identify master and the release commit'
    fi
    if ! git diff --quiet "$_RELEASE_RELEASE_COMMIT" HEAD; then
        _release_stop 'the master merge tree differs from the reviewed release tree' \
                      "$(git diff --name-only "$_RELEASE_RELEASE_COMMIT" HEAD)"
    fi
    if [[ -n $(git status --porcelain) ]]; then
        _release_stop 'the master worktree is not clean after the merge' \
                      "$(git status --short)"
    fi
    _release_run_project_checks
    _release_pass "tested master merge: ${_RELEASE_MERGE_COMMIT:0:12}"
}


_release_tag_master() {
    #
    # Tag the tested master merge after reverifying its version and state.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_tag_master
    #
    local master_version tagged_commit

    _release_begin_step 'Tag the tested master commit'
    if ! _release_capture 'reading svhs_version on master' \
                          bash -c 'source ./s-vhs.sh; svhs_version'; then
        _release_stop 'unable to read svhs_version on master' \
                      "$(tail -n 10 "$_RELEASE_LOG_FILE")"
    fi
    master_version="$(tr -d '\r\n' <"$_RELEASE_LOG_FILE")"
    if [[ $master_version != "$_RELEASE_TARGET_VERSION" ]]; then
        _release_stop 'master svhs_version changed unexpectedly' \
                      "found: ${master_version}; expected: ${_RELEASE_TARGET_VERSION}"
    fi
    if [[ -n $(git status --porcelain) || $(git rev-parse HEAD) != "$_RELEASE_MERGE_COMMIT" ]]; then
        _release_stop 'master moved or became dirty before tagging'
    fi
    if ! git tag "$_RELEASE_TARGET_TAG"; then
        _release_stop "unable to create tag ${_RELEASE_TARGET_TAG}"
    fi
    tagged_commit="$(git rev-parse "refs/tags/${_RELEASE_TARGET_TAG}^{commit}")"
    if [[ $tagged_commit != "$_RELEASE_MERGE_COMMIT" ]]; then
        _release_stop "${_RELEASE_TARGET_TAG} does not identify the tested merge commit"
    fi
    _release_pass "${_RELEASE_TARGET_TAG} identifies ${_RELEASE_MERGE_COMMIT:0:12}"
}


_release_push_master_and_tag() {
    #
    # Push master and only the target tag in one atomic update, then verify
    # both remote refs.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_push_master_and_tag
    #
    local release_push_status remote_refs matching_refs

    _release_begin_step 'Push master and the tag atomically'
    release_push_status=0
    git push --atomic origin "$_RELEASE_MASTER_BRANCH" \
             "refs/tags/${_RELEASE_TARGET_TAG}" || release_push_status=$?
    remote_refs="$(git ls-remote origin \
                        "refs/heads/${_RELEASE_MASTER_BRANCH}" \
                        "refs/tags/${_RELEASE_TARGET_TAG}")"
    matching_refs="$(grep -c "^${_RELEASE_MERGE_COMMIT}" <<< "$remote_refs")"
    if ((matching_refs == 2)); then
        _RELEASE_TAG_PUSHED="verified at ${_RELEASE_MERGE_COMMIT:0:12}"
    else
        _RELEASE_TAG_PUSHED='not verified'
    fi
    if ((release_push_status != 0)); then
        _release_stop "atomic master and tag push exited ${release_push_status}" "$remote_refs"
    fi
    if ((matching_refs != 2)); then
        _release_stop 'origin master or tag does not identify the tested merge commit' "$remote_refs"
    fi
    _release_pass "origin master and ${_RELEASE_TARGET_TAG} identify ${_RELEASE_MERGE_COMMIT:0:12}"
    _release_info 'the tag push started the Release & Deploy workflow'
}


_release_wait_for_publication() {
    #
    # Wait for the workflow-created GitHub release, then verify versioned and
    # latest Pages files plus the documented remote-import form.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_wait_for_publication
    #
    local release_url version_url latest_url
    local release_observed=false
    local status='request failed'
    local attempt published_version

    _release_begin_step 'Wait for GitHub publication and verify Pages'
    release_url="https://github.com/${_RELEASE_GITHUB_REPOSITORY}/releases/tag/${_RELEASE_TARGET_TAG}"
    version_url="${_RELEASE_PAGES_BASE_URL}/${_RELEASE_TARGET_TAG}"
    latest_url="${_RELEASE_PAGES_BASE_URL}/latest"

    _release_info "waiting for ${release_url}"
    for ((attempt = 1; attempt <= _RELEASE_PUBLICATION_ATTEMPTS; attempt++)); do
        if status="$(_release_http_status "$release_url" 2>"$_RELEASE_LOG_FILE")" &&
           [[ $status == 200 ]]; then
            release_observed=true
            break
        fi
        if ((attempt < _RELEASE_PUBLICATION_ATTEMPTS)); then
            if ((attempt % 6 == 0)); then
                _release_info "still waiting for the release workflow (HTTP ${status}, attempt ${attempt})"
            fi
            sleep "$_RELEASE_PUBLICATION_INTERVAL"
        fi
    done

    if [[ $release_observed != true ]]; then
        _RELEASE_GITHUB_STATE="release not observed (last HTTP status: ${status})"
        _release_stop 'the GitHub release was not published in time' \
                      "inspect https://github.com/${_RELEASE_GITHUB_REPOSITORY}/actions/workflows/release.yml"
    fi
    _RELEASE_GITHUB_STATE='GitHub release published; Pages verification pending'
    _release_pass "GitHub publishes ${_RELEASE_TARGET_TAG}"

    _release_verify_published_file 'versioned Pages file' \
                                   "${version_url}?commit=${_RELEASE_MERGE_COMMIT}" \
                                   "${_RELEASE_TMP_DIR}/published-version"
    _release_verify_published_file 'latest Pages file' \
                                   "${latest_url}?commit=${_RELEASE_MERGE_COMMIT}" \
                                   "${_RELEASE_TMP_DIR}/published-latest"

    # The inner Bash receives the URL as $1; $! belongs to its process substitution
    # shellcheck disable=SC2016
    if ! _release_capture 'verifying the documented remote import' \
                          bash -c 'source <(curl -fsSL "$1") && wait "$!" || exit 1; svhs_version' \
                               _ "$version_url"; then
        _release_stop 'the documented remote import failed' \
                      "$(tail -n 10 "$_RELEASE_LOG_FILE")"
    fi
    published_version="$(tr -d '\r\n' <"$_RELEASE_LOG_FILE")"
    if [[ $published_version != "$_RELEASE_TARGET_VERSION" ]]; then
        _release_stop 'the versioned remote import reports an unexpected version' \
                      "found: ${published_version:-missing}; expected: ${_RELEASE_TARGET_VERSION}"
    fi

    _RELEASE_GITHUB_STATE='GitHub release and Pages imports verified'
    _release_pass "remote import reports ${_RELEASE_TARGET_VERSION}"
}


_release_verify_published_file() {
    #
    # Download a published library URL and require an exact byte match with the
    # tagged s-vhs.sh in the current master worktree.
    #
    # Parameters:
    #   $1 - label - artifact described in output.
    #   $2 - url - public URL to download.
    #   $3 - destination - temporary path for the response body.
    #
    # Example:
    #   _release_verify_published_file 'versioned Pages file' "$url" "$file"
    #
    local label="$1"
    local url="$2"
    local destination="$3"

    _release_apply_command "downloading the ${label}" \
                           curl -fsSL --retry 5 --retry-delay 2 \
                                "$url" -o "$destination"
    _release_apply_command "matching the ${label} to s-vhs.sh" \
                           cmp s-vhs.sh "$destination"
}


_release_return_to_develop() {
    #
    # Switch back to develop and verify it is clean at the release commit.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_return_to_develop
    #
    _release_begin_step 'Return to develop'
    if ! git switch "$_RELEASE_DEVELOP_BRANCH"; then
        _release_stop 'unable to return to develop'
    fi
    if [[ -n $(git status --porcelain) ]]; then
        _release_stop 'develop is not clean after the release' "$(git status --short)"
    fi
    if [[ $(git rev-parse HEAD) != "$_RELEASE_RELEASE_COMMIT" ]]; then
        _release_stop 'develop no longer identifies the release commit'
    fi
    _release_pass "develop is clean at ${_RELEASE_RELEASE_COMMIT:0:12}"
}


_release_report_success() {
    #
    # Print the completed release with its GitHub and Pages locations.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _release_report_success
    #
    gum style --border double --border-foreground 42 --foreground 42 \
              --padding '0 2' --margin '1 0' -- \
              "Released ${_RELEASE_PROJECT_NAME} ${_RELEASE_TARGET_TAG}" \
              "GitHub: https://github.com/${_RELEASE_GITHUB_REPOSITORY}/releases/tag/${_RELEASE_TARGET_TAG}" \
              "Pages:  ${_RELEASE_PAGES_BASE_URL}/${_RELEASE_TARGET_TAG}"
}


### Output and shared helpers

_release_pass() {
    #
    # Print a satisfied check or completed action.
    #
    # Parameters:
    #   $1 - message - description of what succeeded.
    #
    # Example:
    #   _release_pass 'ShellCheck succeeded'
    #
    local message="$1"

    printf '%s%s\n' "$(gum style --foreground 42 '✅ ')" "$message"
}


_release_info() {
    #
    # Print a neutral status line.
    #
    # Parameters:
    #   $1 - message - status to report.
    #
    # Example:
    #   _release_info 'nothing was published'
    #
    local message="$1"

    printf '%s %s\n' "$(gum style --foreground 244 '•')" "$message"
}


_release_detail() {
    #
    # Print captured command output as indented, dimmed lines.
    #
    # Parameters:
    #   $1 - detail - multi-line output to print.
    #
    # Example:
    #   _release_detail "$(tail -n 20 "$_RELEASE_LOG_FILE")"
    #
    local detail="$1"
    local lines=()
    local line

    [[ -n $detail ]] || return 0
    while IFS= read -r line || [[ -n $line ]]; do
        lines+=("-> $line")
    done <<< "$detail"
    gum style --faint --margin '0 0 0 2' -- ${lines[@]+"${lines[@]}"}
}


_release_fail() {
    #
    # Print a failed check or release action.
    #
    # Parameters:
    #   $1 - message - description of the failure.
    #   $2 - detail - (optional) - supporting output.
    #
    # Example:
    #   _release_fail 'ShellCheck failed' "$(tail -n 20 "$_RELEASE_LOG_FILE")"
    #
    local message="$1"
    local detail="${2-}"

    printf '%s %s\n' "$(gum style --foreground 196 '✘')" "$message"
    _release_detail "$detail"
}


_release_heading() {
    #
    # Print a framed phase heading.
    #
    # Parameters:
    #   $1 - title - phase name.
    #
    # Example:
    #   _release_heading 'Sanity checks'
    #
    local title="$1"

    gum style --border rounded --border-foreground 212 --foreground 212 \
              --padding '0 2' --margin '1 0 0 0' -- "$title"
}


_release_block() {
    #
    # Record and print a sanity-check blocker without skipping later checks.
    #
    # Parameters:
    #   $1 - message - concise blocker description.
    #   $2 - detail - (optional) - evidence for the blocker.
    #
    # Example:
    #   _release_block 'develop is behind origin/develop'
    #
    local message="$1"
    local detail="${2-}"

    _RELEASE_BLOCKERS+=("$message")
    _release_fail "$message" "$detail"
}


_release_capture() {
    #
    # Run a non-interactive command behind a spinner and capture its output.
    #
    # Parameters:
    #   $1 - title - spinner title.
    #   $2... - command and arguments to run.
    #
    # Example:
    #   _release_capture 'running ShellCheck' shellcheck s-vhs.sh
    #
    local title="$1"
    shift

    # The inner script receives the log path as $0 and must stay unexpanded
    # shellcheck disable=SC2016
    gum spin --spinner minidot --title "$title" -- \
             bash -c 'exec "$@" >"$0" 2>&1' "$_RELEASE_LOG_FILE" ${@+"$@"}
}


_release_apply_command() {
    #
    # Run one non-interactive release command and stop on failure.
    #
    # Parameters:
    #   $1 - title - command description.
    #   $2... - command and arguments to run.
    #
    # Example:
    #   _release_apply_command 'running ShellCheck' shellcheck s-vhs.sh
    #
    local title="$1"
    shift

    if _release_capture "$title" ${@+"$@"}; then
        _release_pass "$title"
        return 0
    fi

    _release_stop "$title failed" "$(tail -n 20 "$_RELEASE_LOG_FILE")"
}


_release_http_status() {
    #
    # Print the final HTTP status for a URL without writing its response body.
    #
    # Parameters:
    #   $1 - url - HTTP URL to request.
    #
    # Example:
    #   status="$(_release_http_status "$release_url")"
    #
    local url="$1"

    curl -L -sS -o /dev/null -w '%{http_code}' "$url"
}


_release_version_is_newer() {
    #
    # Determine whether one stable X.Y.Z version is numerically newer than
    # another.
    #
    # Parameters:
    #   $1 - candidate - stable version that may be newer.
    #   $2 - baseline - stable version to compare against.
    #
    # Example:
    #   _release_version_is_newer '0.3.0' '0.2.0'
    #
    local candidate="$1"
    local baseline="$2"
    local candidate_major candidate_minor candidate_patch
    local baseline_major baseline_minor baseline_patch
    local IFS='.'

    read -r candidate_major candidate_minor candidate_patch <<< "$candidate"
    read -r baseline_major baseline_minor baseline_patch <<< "$baseline"

    if ((10#$candidate_major != 10#$baseline_major)); then
        ((10#$candidate_major > 10#$baseline_major))
        return
    fi
    if ((10#$candidate_minor != 10#$baseline_minor)); then
        ((10#$candidate_minor > 10#$baseline_minor))
        return
    fi
    ((10#$candidate_patch > 10#$baseline_patch))
}


_release_is_allowed_path() {
    #
    # Determine whether a changed path may belong to the release commit.
    #
    # Parameters:
    #   $1 - path - repository-relative path.
    #
    # Example:
    #   _release_is_allowed_path 'CHANGELOG.md'
    #
    local path="$1"
    local allowed_path

    for allowed_path in ${_RELEASE_ALLOWED_PATHS[@]+"${_RELEASE_ALLOWED_PATHS[@]}"}; do
        [[ $path == "$allowed_path" ]] && return 0
    done

    # Reviewed rendered examples and documentation images are optional release files
    [[ $path == examples/*.gif || $path == examples/*.cast || $path == doc/images/* ]] && return 0
    return 1
}


_release_begin_step() {
    #
    # Print the next numbered release-step heading.
    #
    # Parameters:
    #   $1 - title - action about to run.
    #
    # Example:
    #   _release_begin_step 'Validate the release tree'
    #
    local title="$1"

    _RELEASE_STEP_NUMBER=$((_RELEASE_STEP_NUMBER + 1))
    printf '\n%s %s\n' \
           "$(gum style --bold --foreground 212 "[${_RELEASE_STEP_NUMBER}/8]")" "$title"
}


_release_stop() {
    #
    # Report a failed release checkpoint and exit without destructive cleanup.
    #
    # Parameters:
    #   $1 - message - failed checkpoint description.
    #   $2 - detail - (optional) - supporting output.
    #
    # Example:
    #   _release_stop 'atomic push failed'
    #
    local message="$1"
    local detail="${2-}"
    local branch head tag_target

    _release_fail "$message" "$detail"
    branch="$(git branch --show-current 2>/dev/null)"
    head="$(git rev-parse --short HEAD 2>/dev/null)"
    tag_target="$(git rev-parse --short "refs/tags/${_RELEASE_TARGET_TAG}" 2>/dev/null)"

    _release_heading 'Release stopped'
    _release_info "branch: ${branch:-detached}, head: ${head:-unknown}"
    _release_info "develop push: ${_RELEASE_DEVELOP_PUSHED}"
    _release_info "master and ${_RELEASE_TARGET_TAG} push: ${_RELEASE_TAG_PUSHED}"
    _release_info "GitHub: ${_RELEASE_GITHUB_STATE}"
    _release_info "local ${_RELEASE_TARGET_TAG}: ${tag_target:-absent}"
    _release_info 'no later step ran; inspect this state before retrying'
    exit 1
}


main ${@+"$@"}
