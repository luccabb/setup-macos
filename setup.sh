#!/usr/bin/env bash
set -euo pipefail

# installing brew
sudo mkdir -p /opt/homebrew
sudo chown -R "$(whoami)":admin /opt/homebrew
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# installing miniconda
brew install --cask miniconda
conda init bash
conda init zsh

# setting up github
current_name="$(git config --global user.name || true)"
current_email="$(git config --global user.email || true)"

echo "Configure your global Git identity"
echo "Press Enter to keep the current value shown in [brackets]."
echo

read -r -p "Your name  [${current_name:-none}]: " name
name="${name:-$current_name}"

read -r -p "Your email [${current_email:-none}]: " email
email="${email:-$current_email}"

git config --global user.email "$email"
git config --global user.name "$name"
ssh-keyygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N "" -q
eval "$(ssh-agent -s)"\nssh-add --apple-use-keychain ~/.ssh/id_ed25519
cat >> ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
  StrictHostKeyChecking accept-new
EOF
chmod 600 ~/.ssh/config
brew install gh
gh config set git_protocol ssh
# default to merge
git config --global pull.rebase false
gh auth login --hostname github.com --git-protocol ssh --web

