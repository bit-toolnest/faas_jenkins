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

# 3) Uninstall Jenkins
# Stop and disable Jenkins
sudo systemctl stop jenkins
sudo systemctl disable jenkins

# Remove Jenkins package
sudo apt purge jenkins -y

# Clean up leftover directories
sudo rm -rf /var/lib/jenkins /etc/jenkins /var/log/jenkins

# Final cleanup
sudo apt autoremove -y
sudo apt clean


echo "🎯 Jenkins settings uninstall process finished!"
