#!/bin/bash
set -e

echo "=== Jenkins + faasd + Docker Installer (Dependency Check Mode) ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1) Verify Java 17 JDK
if ! java -version 2>&1 | grep -q "17"; then
  echo "❌ Java 17 JDK not found. Please install OpenJDK 17 before running this installer."
  exit 1
else
  echo "✅ Java 17 JDK detected"
fi

# 2) Verify faas-cli
if ! command -v faas-cli >/dev/null 2>&1; then
  echo "❌ faas-cli not found. Please install faas-cli before running this installer."
  exit 1
else
  echo "✅ faas-cli detected"
fi

# 3) Verify Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker not found. Please install Docker before running this installer."
  exit 1
else
  echo "✅ Docker detected"
fi

# 4) Verify Jenkins
if ! systemctl status jenkins >/dev/null 2>&1; then
  echo "❌ Jenkins service not found. Please install Jenkins before running this installer."
  exit 1
else
  echo "✅ Jenkins detected"
fi

# 5) Add Jenkins user to docker group
echo "➡ Adding Jenkins user to docker group..."
sudo usermod -aG docker jenkins || true


# 6) for credential parsing
echo "➡ for credential parsing..."
sudo apt install jq xmlstarlet -y

# 7) GitHub credentials setup (from JSON/XML file)
CRED_FILE=${GITHUB_CRED_FILE:-"./github-creds.json"}   # default to JSON file
if [[ -f "$CRED_FILE" ]]; then
    echo "➡ Reading GitHub credentials from $CRED_FILE..."

    if [[ "$CRED_FILE" == *.json ]]; then
        # Requires jq
        GITHUB_TOKEN_INPUT=$(jq -r '.token' "$CRED_FILE")
        GITHUB_ADMIN_USER_INPUT=$(jq -r '.admin_user' "$CRED_FILE")
        GITHUB_ORG_INPUT=$(jq -r '.org' "$CRED_FILE")
    elif [[ "$CRED_FILE" == *.xml ]]; then
        # Requires xmlstarlet
        GITHUB_TOKEN_INPUT=$(xmlstarlet sel -t -v "//credentials/token" "$CRED_FILE")
        GITHUB_ADMIN_USER_INPUT=$(xmlstarlet sel -t -v "//credentials/admin_user" "$CRED_FILE")
        GITHUB_ORG_INPUT=$(xmlstarlet sel -t -v "//credentials/org" "$CRED_FILE")
    else
        echo "❌ Unsupported credential file format: $CRED_FILE"
        exit 1
    fi

    echo "➡ Writing environment variables to /etc/environment..."
    sudo sed -i '/GITHUB_TOKEN=/d' /etc/environment
    sudo sed -i '/GITHUB_ADMIN_USER=/d' /etc/environment
    sudo sed -i '/GITHUB_ORG=/d' /etc/environment

    echo "GITHUB_TOKEN=${GITHUB_TOKEN_INPUT}" | sudo tee -a /etc/environment >/dev/null
    echo "GITHUB_ADMIN_USER=${GITHUB_ADMIN_USER_INPUT}" | sudo tee -a /etc/environment >/dev/null
    echo "GITHUB_ORG=${GITHUB_ORG_INPUT}" | sudo tee -a /etc/environment >/dev/null

    # 8) Deploy Jenkins credentials.xml from separate file
    CRED_FILE_SRC="$SCRIPT_DIR/credentials.xml"
    CRED_FILE_DST="/var/lib/jenkins/credentials.xml"
    sed "s|\${GITHUB_ADMIN_USER}|$GITHUB_ADMIN_USER_INPUT|g; s|\${GITHUB_TOKEN}|$GITHUB_TOKEN_INPUT|g" "$CRED_FILE_SRC" | sudo tee "$CRED_FILE_DST" >/dev/null
    
    if [ -f "$CRED_FILE_SRC" ]; then
      echo "➡ Deploying Jenkins credentials.xml"
      sudo cp "$CRED_FILE_SRC" "$CRED_FILE_DST"
      sudo chown jenkins:jenkins "$CRED_FILE_DST"
      echo "✅ Jenkins credentials deployed"
    else
      echo "⏭ Skipping credentials deployment (file not found)"
    fi
    
    # 9) Deploy Organization Folder config.xml from separate file
    ORG_JOB_DIR="/var/lib/jenkins/jobs/${GITHUB_ORG}-org"
    ORG_JOB_FILE="$ORG_JOB_DIR/config.xml"
    ORG_FILE_SRC="$SCRIPT_DIR/org-folder-config.xml"
    
    if [ -f "$ORG_FILE_SRC" ]; then
      echo "➡ Deploying Organization Folder config.xml for org: ${GITHUB_ORG}"
      sudo mkdir -p "$ORG_JOB_DIR"
      sudo cp "$ORG_FILE_SRC" "$ORG_JOB_FILE"
      sudo chown -R jenkins:jenkins "$ORG_JOB_DIR"
      echo "✅ Organization Folder job created at $ORG_JOB_DIR"
    else
      echo "⏭ Skipping Organization Folder deployment (file not found)"
    fi

    echo "➡ Reloading environment..."
    source /etc/environment || true

    echo "➡ Restarting Jenkins to apply new environment variables..."
    sudo systemctl restart jenkins
    echo "✅ Jenkins restarted and environment variables applied"
    
else
    echo "⏭ Skipping GitHub credential and pipeline setup (no credential file found)"
fi

echo "🎯 Installer finished successfully (all dependencies verified)"
