# setting up a new macos machine

## running
```shell
git clone git@github.com:luccabb/setup-macos.git
./setup-macos/setup.sh
```
## what [`setup.sh`](https://github.com/luccabb/setup-macos/blob/main/setup.sh) does
- installs [`brew`](https://brew.sh/)
- installs [Claude Code](https://claude.ai/code)
- installs cask apps: [iTerm2](https://iterm2.com/), [VS Code](https://code.visualstudio.com/), [Flux](https://justgetflux.com/), [Obsidian](https://obsidian.md/), [Docker](https://www.docker.com/), (mini)[`conda`](https://www.anaconda.com/docs/getting-started/miniconda/main)
- sets up github: [`gh` CLI](https://github.com/cli/cli), creates and uploads an ssh key for your new mac to your git account
- installs [starship](https://starship.rs/)
- installs [neovim](https://neovim.io/) and sets it as the default editor
- installs [uv](https://docs.astral.sh/uv/)
- installs [Node.js](https://nodejs.org/) and [Codex CLI](https://github.com/openai/codex)
- installs [Google Chrome](https://www.google.com/chrome/) and sets it as the default browser
- applies macOS system settings (key repeat, autocorrect, Spotlight)
- configures the Dock
