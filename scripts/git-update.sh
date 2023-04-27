#!/bin/bash
git fetch origin HEAD

# Check if the default branch is being used
current_branch=$(git rev-parse --abbrev-ref HEAD)
default_branch=$(basename $(git rev-parse --abbrev-ref origin/HEAD))
if [[ "$current_branch" != "$default_branch" ]]; then
    read -p "Not in default branch. Assuming developer and aborting update."
    exit 0
fi

# If there are no differences between the local default
# and the remote default, no update required.
if git diff --quiet --exit-code HEAD..origin/HEAD; then
    echo "No updates."
    exit 0
fi

# Get the number of commits that HEAD is ahead of origin/HEAD
ahead=$(git rev-list --left-right --count origin/HEAD...HEAD | gawk '{print $2}')
if [[ $ahead -ne 0 ]]; then
    read -p "HEAD is ahead of origin by $ahead commits. Assuming developer and aborting update."
    exit 0
fi

# Check for uncommitted changes
if ! git diff --quiet --exit-code HEAD; then
    echo "You have uncommitted changes to the following files."
    git diff --name-only HEAD
    if source user-prompt-yn.sh "Keep uncommitted change and defer update?"; then
        echo "Deferring update."
        sleep 2s
        exit 0
    else
        echo "Resetting uncommitted changes."
        git reset --hard HEAD
    fi
fi

echo "The following updates are available."
git log --oneline --no-decorate HEAD~${ahead}..HEAD
if ! source user-prompt-yn.sh "Do you accept them?"; then
    echo "Deferring update."
    sleep 2s
    exit 0
fi

if git merge --ff-only; then
    read -p "Update complete."
else
    read -p "Problem occurred while updating."
fi
