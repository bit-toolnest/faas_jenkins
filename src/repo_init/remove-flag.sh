#!/bin/bash
set -e

REPO="$1"
ORG="$2"

ADMIN_USER="${ADMIN_USER:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$ADMIN_USER" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub credentials not available"
    exit 1
fi

if [ -f ".jenkins/first-run.flag" ]; then
    echo "Removing .jenkins/first-run.flag..."

    git config --global user.name "Jenkins Automation"
    git config --global user.email "jenkins@${ORG}.local"

    git rm .jenkins/first-run.flag || true
    git commit -m "Remove first-run flag after initial setup" || true
    git push https://${ADMIN_USER}:${GITHUB_TOKEN}@github.com/${ORG}/${REPO}.git HEAD:main || true

    echo "Flag removed and pushed."
else
    echo "Flag not found, skipping."
fi
