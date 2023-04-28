#!/bin/bash
# Source this script.
# It implements a process that fast-forwards a repository, if possible.
# There are some cases where user input is required for decisions.
this_script_dir=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

git fetch origin HEAD

# Check if the default branch is being used
current_branch=$(git rev-parse --abbrev-ref HEAD)
default_branch=$(basename $(git rev-parse --abbrev-ref origin/HEAD))
if [[ "$current_branch" != "$default_branch" ]]; then
    echo "Current branch ($current_branch) differs from default branch ($default_branch)."
    read -p "Assuming developer and aborting update."
    return 0
fi

# If there are no differences between the local default
# and the remote default, no update required.
if git diff --quiet --exit-code HEAD..origin/HEAD; then
    echo "No updates."
    return 0
fi

# Get the number of commits that origin/HEAD is ahead of HEAD
ahead=$(git rev-list --left-right --count origin/HEAD...HEAD | gawk '{print $2}')
if [[ $ahead -ne 0 ]]; then
    read -p "HEAD is ahead of origin by $ahead commits. Assuming developer and aborting update."
    return 0
fi

# Check for uncommitted changes
if ! git diff --quiet --exit-code HEAD; then
    echo "You have uncommitted changes to the following files."
    git diff --name-only HEAD
    if source ${this_script_dir}/user-prompt-yn.sh "Keep uncommitted change and defer update?"; then
        echo "Deferring update."
        sleep 2s
        return 0
    else
        echo "Resetting uncommitted changes."
        git reset --hard HEAD
    fi
fi

echo "The following updates are available."
git log --oneline --no-decorate origin/HEAD..HEAD
if ! source ${this_script_dir}/user-prompt-yn.sh "Do you accept them?"; then
    echo "Deferring update."
    sleep 2s
    return 0
fi

if git merge --ff-only; then
    read -p "Update complete."
else
    read -p "Problem occurred while updating."
fi
