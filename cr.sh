#!/bin/bash

# Function to generate a random branch name
generate_random_branch_name() {
  while true; do
    BRANCH_NAME="cr$(shuf -i 1000-9999 -n 1)"
    # Check if the branch name already exists locally or remotely
    if ! git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" && ! git ls-remote --exit-code origin "refs/heads/$BRANCH_NAME"; then
      echo "$BRANCH_NAME"
      break
    fi
  done
}

# Replace these variables with your own values
BASE_BRANCH="main"
PULL_REQUEST_TITLE="Add pull request title"
PULL_REQUEST_BODY="Add pull request description"
REMOTE_NAME="origin"

# Generate a random branch name
NEW_BRANCH=$(generate_random_branch_name)

# Create a new branch with the random name
git checkout -b "$NEW_BRANCH"

# Push the new branch to the remote repository
git push "$REMOTE_NAME" "$NEW_BRANCH"

# Create a pull request using GitHub CLI (gh)
gh pr create --base "$BASE_BRANCH" --head "$NEW_BRANCH" --title "$PULL_REQUEST_TITLE" --body "$PULL_REQUEST_BODY"

# Get the pull request URL
PR_URL=$(gh pr view --json url --jq '.url')

# Output the pull request URL and the branch name to the terminal
echo "Pull request created: $PR_URL"
echo "Branch name: $NEW_BRANCH"
