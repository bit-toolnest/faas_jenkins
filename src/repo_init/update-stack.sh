#!/bin/bash
set -e

REPO="$1"
ORG="$2"

# Jenkins injects these via withCredentials
ADMIN_USER="${ADMIN_USER:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$ADMIN_USER" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub credentials not available"
    exit 1
fi

STACK_FILE="stack.yml"

if [ -f "$STACK_FILE" ]; then
    echo "Replacing \$functionname with ${REPO} in stack.yml..."

    sed -i "s|\$functionname|${REPO}|g" "$STACK_FILE"

    echo "stack.yml updated successfully."

    git config --global user.name "Jenkins Automation"
    git config --global user.email "jenkins@${ORG}.local"

    git add "$STACK_FILE"
    if ! git diff --cached --quiet; then
        git commit -m "Update stack.yml placeholders to ${REPO}"
        git push https://${ADMIN_USER}:${GITHUB_TOKEN}@github.com/${ORG}/${REPO}.git HEAD:main || true
    else
        echo "No changes to commit in stack.yml"
    fi
else
    echo "Warning: stack.yml not found, skipping update."
fi
