#!/bin/bash
set -e

REPO="$1"
ORG="$2"

# Jenkins injects these via withCredentials if needed
ADMIN_USER="${ADMIN_USER:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo "➡ Checking gradlew executable permission..."

if [ -f "gradlew" ]; then
    if [ ! -x "gradlew" ]; then
        echo "⚠ gradlew found but not executable. Fixing..."
        chmod +x gradlew
        echo "✅ gradlew is now executable"

        # Commit and push the permission change back to GitHub
        git config --global user.name "Jenkins Automation"
        git config --global user.email "jenkins@${ORG}.local"

        git add gradlew
        git commit -m "Set gradlew executable permission" || true

        if [ -n "$ADMIN_USER" ] && [ -n "$GITHUB_TOKEN" ]; then
            git push https://${ADMIN_USER}:${GITHUB_TOKEN}@github.com/${ORG}/${REPO}.git HEAD:main || true
        else
            echo "⏭ GitHub credentials not available, skipping push"
        fi
    else
        echo "✅ gradlew already executable"
    fi
else
    echo "⏭ gradlew not found, skipping"
fi
