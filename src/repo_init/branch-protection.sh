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

TEMPLATE_SRC="/opt/scripts/branch-protection-rule.json"

if [ ! -f "$TEMPLATE_SRC" ]; then
    echo "Error: Template file not found: $TEMPLATE_SRC"
    exit 1
fi

echo "➡ Resolving branch protection rule from template..."

# Generate resolved JSON in memory
RESOLVED_JSON=$(sed \
    -e "s|\${ADMIN_USER}|${ADMIN_USER}|g" \
    -e "s|\${REPO}|${REPO}|g" \
    -e "s|\${ORG}|${ORG}|g" \
    "$TEMPLATE_SRC")

echo "➡ Applying branch protection rules for ${ORG}/${REPO}..."

# Send resolved JSON directly to GitHub
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  --data "${RESOLVED_JSON}" \
  "https://api.github.com/repos/${ORG}/${REPO}/branches/main/protection"

echo "✅ Branch protection applied successfully."

