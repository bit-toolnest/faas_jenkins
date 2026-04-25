#!/bin/bash
set -e

echo "=== Jenkins Settings Uninstaller Script ==="

# 1) Remove Jenkins user from docker group
if id -nG jenkins 2>/dev/null | grep -qw "docker"; then
  echo "➡ Removing Jenkins user from docker group..."
  sudo gpasswd -d jenkins docker || true
  echo "✅ Jenkins user removed from docker group"
else
  echo "⏭ Jenkins user was not in docker group"
fi

# 2) Remove GitHub credentials from /etc/environment
echo "➡ Removing GitHub credentials from /etc/environment..."
sudo sed -i '/GITHUB_TOKEN=/d' /etc/environment
sudo sed -i '/GITHUB_ADMIN_USER=/d' /etc/environment
sudo sed -i '/GITHUB_ORG=/d' /etc/environment
echo "✅ GitHub credentials removed"

# 3) Reload environment and restart Jenkins
echo "➡ Reloading environment..."
source /etc/environment || true

echo "➡ Restarting Jenkins to apply changes..."
sudo systemctl restart jenkins || true

echo "🎯 Jenkins settings uninstall process finished!"
