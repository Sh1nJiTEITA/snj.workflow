# snj dotfiles

A modular, automated environment manager for Arch Linux by and for snj.

## Quick Start

To deploy or update the environment, clone this repo into `~/dotfiles` and run the installer:

```bash
./install.sh -p -l
```

### Command Flags
| Flag | Description |
| :--- | :--- |
| `-p` | **Pull/Update**: Syncs repos and installs system dependencies. |
| `-l` | **Link**: Uses GNU Stow to symlink configs to your `$HOME`. |
| `-u` | **Unlink**: Removes symlinks (clean teardown). |
| `-d` | **Debug**: Enables SSH agent for GitHub and verbose bash tracing (`set -x`). |
| `-b` | **Bash Trace**: Quick trace without the SSH agent overhead. |

---

## Architecture

The system is split into three distinct layers:

### 1. The Core (Bash)
The `install.sh` script is the brain. It handles:
* **Dependency Resolution**: Automatically installs `stow`, `oh-my-zsh`, and `oh-my-posh`.
* **AUR Bootstrapping**: Detects if an AUR helper is missing and builds `paru-bin` from source.
* **Smart Repo Management**: Uses a custom `check_repo` function to handle recursive cloning and submodule updates.

### 2. The Packages (GNU Stow)
Configs are organized into modular "Stow packages." When linked, they mimic the structure of your home directory:
* `nvim/` → `~/.config/nvim`
* `kitty/` → `~/.config/kitty`
* `zsh/` → `~/.zshrc` (via the Zsh Post-Hook)

### 3. The System (Arch Meta-Package)
Instead of a long list of `pacman` commands, this repo utilizes a local meta-package: `snj.arch_dependencies`.
* **Location**: `~/dotfiles/arch_dependencies/PKGBUILD`
* **Purpose**: Manages all official binary dependencies (Node, Lua, Neovim, etc.) in one place.

---

## The Zsh Post-Hook

One of the unique features of this setup is the **Dynamic Source Hook**. 
Instead of a static, messy `.zshrc`, the installer scans `zsh/.config/zsh/` for any `.zsh` files (aliases, exports, startups) and automatically writes a clean `source` list into the main `~/.zshrc`. 

> **Note:** If you add a new `.zsh` file, just re-run `./install.sh -p` to register it.

---

## Look & Feel
* **Terminal**: Kitty
* **Shell**: Zsh + Oh-My-Zsh + Oh-My-Posh
* **Font**: JetBrainsMono Nerd Font (Auto-installed via `paru`)
* **Editor**: Neovim (Custom modular config)

---

## Requirements
* **OS**: Arch Linux
* **Sudo**: Required for package installation.
* **SSH**: If using `-d`, ensure your private key is at `~/.ssh/github`.
