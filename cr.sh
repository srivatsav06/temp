#!/bin/bash

# Function to generate a branch name based on the pull request number
generate_branch_name() {
  local PR_NUMBER=$(gh pr list --state open --limit 1 --json number --jq '.[0].number')
  if [ -n "$PR_NUMBER" ]; then
    printf "cr%05d" "$PR_NUMBER"
  else
    echo "Unable to retrieve the pull request number."
    exit 1
  fi
}

# Replace these variables with your own values
BASE_BRANCH="main"
PULL_REQUEST_TITLE="Add title"
PULL_REQUEST_BODY="Add description."
REMOTE_NAME="origin"

# Generate a branch name based on the pull request number
NEW_BRANCH=$(generate_branch_name)

# Create a new branch with the generated name
git checkout -b "$NEW_BRANCH"

# Push the new branch to the remote repository
git push "$REMOTE_NAME" "$NEW_BRANCH"

# Create a pull request using GitHub CLI (gh)
gh pr create --base "$BASE_BRANCH" --head "$NEW_BRANCH" --title "$PULL_REQUEST_TITLE" --body "$PULL_REQUEST_BODY"

# Get the pull request URL
PR_URL=$(gh pr view --json url --jq '.url')

git checkout "$BASE_BRANCH"
git branch -d "$NEW_BRANCH"

# Output the pull request URL and the branch name to the terminal
echo "Pull request created: $PR_URL"
echo "Branch name: $NEW_BRANCH"
