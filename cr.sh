#!/bin/bash

# Function to generate a branch name based on the pull request number
get_branch_name() {
  local PR_NUMBER="$1"
  echo "cr$(printf "%05d" "$PR_NUMBER")"
}

# Function to create a new branch or checkout an existing branch
create_or_checkout_branch() {
  local BRANCH_NAME="$1"
  git checkout "$BRANCH_NAME" 2>/dev/null || git checkout -b "$BRANCH_NAME"
}

# Function to check if a branch exists either locally or remotely
branch_exists() {
  local BRANCH_NAME="$1"
  if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" || \
     git ls-remote --exit-code origin "refs/heads/$BRANCH_NAME"; then
    echo "true"
  else
    echo "false"
  fi
}

# Function to generate a random branch name
generate_random_branch_name() {
  while true; do
    BRANCH_NAME="cr$(shuf -i 10000-99999 -n 1)"
    # Check if the branch name already exists locally or remotely
    if [ "$(branch_exists "$BRANCH_NAME")" == "false" ]; then
      echo "$BRANCH_NAME"
      break
    fi
  done
}

generate_branch_name() {
  local LATEST_PR=$(gh pr list --state open --limit 1 --json number --jq '.[0].number')
  if [ -n "$LATEST_PR" ]; then
    LATEST_PR=LATEST_PR+1
    printf "cr%05d" "$((LATEST_PR + 1))"
  else
    # If no open pull requests, get the highest closed pull request number
    local HIGHEST_CLOSED_PR=$(gh pr list --state closed --limit 1 --json number --jq '.[0].number')
    if [ -n "$HIGHEST_CLOSED_PR" ]; then
      printf "cr%05d" "$((HIGHEST_CLOSED_PR + 1))"
    else
      # If no closed pull requests either, start from 1
      local NEW_PR=$(1)
      printf "cr%05d" "$NEW_PR"
    fi
  fi
}

## Function to generate a branch name based on the pull request number
#generate_branch_name() {
#  local PR_NUMBER=$(gh pr list --state open --limit 1 --json number --jq '.[0].number')
#  if [ -n "$PR_NUMBER" ]; then
#    printf "cr%05d" "$PR_NUMBER"
#  else
#    echo "Unable to retrieve the pull request number."
#    exit 1
#  fi
#}

# Replace these variables with your own values
BASE_BRANCH="main"
PULL_REQUEST_TITLE="Add title"
PULL_REQUEST_BODY="Add description."
REMOTE_NAME="origin"

# Check if the script was provided with an argument like '-r 5'
if [ "$#" -eq 2 ] && [ "$1" = "-r" ]; then
  # Extract the pull request number from the argument
  TARGET_PR_NUMBER="$2"

  # Get the corresponding branch name
  TARGET_BRANCH=$(get_branch_name "$TARGET_PR_NUMBER")

  # Check if the target branch exists locally or remotely
  if [ "$(branch_exists "$TARGET_BRANCH")" == "false" ]; then
    echo "Branch '$TARGET_BRANCH' does not exist locally or remotely."
    exit 1
  fi

  create_or_checkout_branch "$TARGET_BRANCH"

  # Push the new commits to the random branch
  git push "$REMOTE_NAME" "$TARGET_BRANCH"

  git checkout "$BASE_BRANCH"
  git branch -d "$TARGET_BRANCH"
else
  # Generate a branch name based on the pull request number
  NEW_BRANCH=$(generate_branch_name)

  # Check if the branch name already exists locally or remotely
  if [ "$(branch_exists "$NEW_BRANCH")" == "true" ]; then
    # Generate a random branch name if it already exists
    NEW_BRANCH=$(generate_random_branch_name)
  fi

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
fi
