#!/usr/bin/env bash
set -uo pipefail

log() { echo "==> $*"; }

# cache sudo credentials and keep them alive for the duration of the script
log "Caching sudo credentials"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT

# never sleep (run early while sudo is fresh)
log "Configuring sleep settings"
sudo pmset -a disablesleep 1
sudo pmset -a sleep 0
sudo pmset -a displaysleep 0

# installing brew
log "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew"
  sudo mkdir -p /opt/homebrew
  sudo chown -R "$(whoami)":admin /opt/homebrew
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo >> ~/.zprofile
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
else
  log "Homebrew already installed, skipping"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# claude
log "Checking Claude"
if ! command -v claude &>/dev/null; then
  log "Installing Claude"
  curl -fsSL https://claude.ai/install.sh | bash
else
  log "Claude already installed, skipping"
fi

# cask apps
brew_cask_install() {
  if brew list --cask "$1" &>/dev/null; then
    log "$1 already installed, skipping"
  else
    log "Installing $1"
    brew install --cask "$1" --adopt || true
  fi
}
brew_cask_install iterm2
brew_cask_install visual-studio-code
brew_cask_install flux
brew_cask_install obsidian
brew_cask_install miniconda
brew_cask_install docker

# miniconda init (conda won't be in PATH yet after cask install, use full path)
log "Checking conda init"
CONDA_BIN="/opt/homebrew/Caskroom/miniconda/base/bin/conda"
if [ -f "$CONDA_BIN" ] && ! grep -q 'conda initialize' ~/.zshrc 2>/dev/null; then
  log "Initializing conda"
  "$CONDA_BIN" init bash
  "$CONDA_BIN" init zsh
else
  log "conda already initialized, skipping"
fi

# setting up github
log "Configuring Git identity"
current_name="$(git config --global user.name || true)"
current_email="$(git config --global user.email || true)"

echo "Configure your global Git identity"
echo "Press Enter to keep the current value shown in [brackets]."
echo

read -r -e -p "Your name  [${current_name:-none}]: " name
name="${name:-$current_name}"

read -r -e -p "Your email [${current_email:-none}]: " email
email="${email:-$current_email}"

git config --global user.email "$email"
git config --global user.name "$name"

log "Checking SSH key"
if [ ! -f ~/.ssh/id_ed25519 ]; then
  log "Generating SSH key"
  ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N "" -q
  eval "$(ssh-agent -s)" && ssh-add --apple-use-keychain ~/.ssh/id_ed25519
else
  log "SSH key already exists, skipping"
fi

log "Checking SSH config"
if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
  log "Writing SSH config"
  mkdir -p ~/.ssh && touch ~/.ssh/config
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
else
  log "SSH config already set, skipping"
fi

log "Installing gh"
brew install gh
gh config set git_protocol ssh
git config --global pull.rebase false

log "Checking GitHub auth"
if ! gh auth status --hostname github.com &>/dev/null; then
  log "Logging into GitHub"
  gh auth login --hostname github.com --git-protocol ssh --web
else
  log "Already authenticated with GitHub, skipping"
fi

# install starship
log "Checking Starship"
if ! command -v starship &>/dev/null; then
  log "Installing Starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  log "Starship already installed, skipping"
fi

mkdir -p ~/.config && touch ~/.config/starship.toml
cat > ~/.config/starship.toml <<'TOML'
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

[character]
success_symbol = '[➜](bold green)'

[package]
disabled = true
TOML
grep -q 'starship init zsh' ~/.zshrc || echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# NEOVIM
log "Installing Neovim"
export NONINTERACTIVE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1
brew install neovim
grep -q 'alias vim="nvim"' ~/.zshrc || echo 'alias vim="nvim"' >> ~/.zshrc
grep -q 'alias vi="nvim"'  ~/.zshrc || echo 'alias vi="nvim"'  >> ~/.zshrc
grep -q 'EDITOR="nvim"'    ~/.zshrc || echo 'export EDITOR="nvim"' >> ~/.zshrc
grep -q 'VISUAL="nvim"'    ~/.zshrc || echo 'export VISUAL="nvim"' >> ~/.zshrc
git config --global core.editor "nvim"

# uv
log "Checking uv"
if ! command -v uv &>/dev/null; then
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  log "uv already installed, skipping"
fi
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# iterm2 settings
log "Configuring iTerm2"
defaults write com.googlecode.iterm2 AllowClipboardAccess -bool true

# macos system settings
log "Applying macOS system settings"
defaults write com.apple.spotlight CalculationEnabled -bool YES
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 1
/usr/bin/hidutil property --set '{"CapsLockDelayOverride": 0}'

# dock
log "Configuring Dock"
brew install dockutil || true
dockutil --add /Applications/Obsidian.app --no-restart || true
dockutil --add "/Applications/Visual Studio Code.app" --no-restart || true
dockutil --add "/Applications/Google Chrome.app" --no-restart || true
dockutil --add /Applications/iTerm.app --no-restart || true
killall Dock

# chrome as default browser
log "Installing Google Chrome"
brew_cask_install google-chrome
log "Setting Chrome as default browser"
brew install defaultbrowser || true
defaultbrowser chrome || true

log "Done!"
