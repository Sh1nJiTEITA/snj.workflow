#!/bin/bash

# FLAGS:
DEBUG=false
UPDATE=false
LINK=false
UNLINK=false

DOTFILES_DIR=~/dotfiles
mkdir -p ${DOTFILES_DIR}
echo "Current dotfiles directory path is ${ANSI_BLUE}${DOTFILES_DIR}${ANSI_RESET}"

while getopts "dplub" opt; do
    case $opt in
    d) # DEBUG
        DEBUG=true
        echo "Debug mode: ON"
        ;;
    p) # PULL
        UPDATE=true
        echo "Pulling mode: ON"
        ;;
    l) # LINK
        LINK=true
        echo "Linking mode: ON"
        ;;
    u) # UNLINK
        UNLINK=true
        echo "Unlinking mode: ON"
        ;;
    b) # bash debug
        set -x
        ;;
    \?)
        echo "Invalid option: -${OPTARG}" >&2
        exit 1
        ;;
    esac
done

if [[ "$LINK" = true && "$UNLINK" = true ]]; then
    echo "Cant link & unlink at the same time"
    exit 1
fi

if [[ "$DEBUG" = true ]]; then
    eval $(ssh-agent)
    ssh-add ~/.ssh/github
fi

ANSI_BLACK=$'\e[0;30m'
ANSI_RED=$'\e[0;31m'
ANSI_GREEN=$'\e[0;32m'
ANSI_YELLOW=$'\e[0;33m'
ANSI_BLUE=$'\e[0;34m'
ANSI_PURPLE=$'\e[0;35m'
ANSI_CYAN=$'\e[0;36m'
ANSI_WHITE=$'\e[0;37m'
ANSI_RESET=$'\e[0m'

function prefix_scope { echo "$1 ${ANSI_PURPLE}$2${ANSI_RESET}..."; }
function postfix_scope {
    echo "$1 ${ANSI_PURPLE}$2${ANSI_RESET}... ${ANSI_BLUE}DONE${ANSI_RESET}"
    echo ""
}

CHECK_REPO_RETURN_VALUE=""
function check_repo {
    GIT_URL=$1
    STOW_PATH=$2
    ABS_PATH="${DOTFILES_DIR}/${STOW_PATH}"
    SKIP_LINKS="${3:-false}"

    ELEMENT_NAME=$(basename "${ABS_PATH}")

    echo ""
    if [[ "$UPDATE" = true ]]; then
        prefix_scope "Working with repo ${ANSI_BLUE}${GIT_URL}${ANSI_RESET}"

        if [ ! -d ${ABS_PATH} ]; then
            echo "Cloning repo"
            OUTPUT=$(git clone --recursive ${GIT_URL} ${ABS_PATH})
        else
            echo "Pulling repo"
            OUTPUT=$(git -C ${ABS_PATH} pull 2>&1)
            OUTPUT+=$'\n'$(git -C ${ABS_PATH} submodule update --init --recursive 2>&1)
        fi
    fi

    if [[ "$SKIP_LINKS" = false && "$LINK" = true ]]; then
        echo "Linking ${ELEMENT_NAME}"
        stow -d "${DOTFILES_DIR}" "${ELEMENT_NAME}"
    fi

    if [[ "$SKIP_LINKS" = false && "$UNLINK" = true ]]; then
        echo "Unlinking ${ELEMENT_NAME}"
        stow -D -d "${DOTFILES_DIR}" "${ELEMENT_NAME}"
    fi

    echo "Endpoint path is ${ANSI_BLUE}${ABS_PATH}${ANSI_RESET}"

    echo "Ended with comment ${ANSI_YELLOW}${OUTPUT}${ANSI_RESET}"
    postfix_scope "Working with repo ${ANSI_BLUE}${GIT_URL}${ANSI_RESET}"

    CHECK_REPO_RETURN_VALUE="${ABS_PATH}"
}

#####################################################################################
if [ "$UPDATE" = true ]; then
    prefix_scope "Checking" "system dependencies"

    check_repo "https://github.com/sh1njiteita/snj.arch_dependencies.git" "arch_dependencies" true

    if [ "$DEBUG" = true ]; then
        echo "Intalling system dependencies from local <dir>/PKGBUILD"
        (cd "arch_dependencies" && makepkg -sfi --noconfirm)
    else
        echo "Intalling system dependencies from repo"
        (cd "${DOTFILES_DIR}/arch_dependencies" && makepkg -si --needed --noconfirm)
    fi

    postfix_scope "Checking" "system dependencies"
fi
#####################################################################################

#####################################################################################
if [ "$UPDATE" = true ]; then
    prefix_scope "Checking" "GNU stow"
    if ! command -v stow &>/dev/null; then
        prefix_scope "Installing" "GNU stow"
        sudo pacman -S --needed stow
        postfix_scope "Installing" "GNU stow"
    else
        echo "GNU stow is installed"
    fi
    postfix_scope "Checking" "GNU stow"
fi
#####################################################################################

#####################################################################################
if [ "$UPDATE" = true ]; then
    prefix_scope "Checking" "oh-my-zsh"
    if [ ! -d ${HOME}/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "oh-my-zsh is installed"
    fi
    postfix_scope "Checking" "oh-my-zsh"
fi
#####################################################################################

#####################################################################################
if [ "$UPDATE" = true ]; then
    prefix_scope "Checking" "oh-my-posh"
    if [ ! -d ${HOME}/.oh-my-posh ]; then
        mkdir -p ~/.oh-my-posh
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.oh-my-posh
    else
        echo "oh-my-posh is installed"
    fi
    postfix_scope "Checking" "oh-my-posh"
fi
#####################################################################################

####################################################################################
if [ "$UPDATE" = true ]; then
    prefix_scope "Checking" "AUR helper (paru)"
    if ! command -v paru &>/dev/null; then
        echo "paru not found. Bootstrapping from AUR..."
        # We use a temp directory so we don't clutter your dotfiles
        git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
        (cd /tmp/paru-bin && makepkg -si --noconfirm)
        rm -rf /tmp/paru-bin
    fi

    # Now use paru to install your Nerd Fonts
    echo "Installing Nerd Fonts via paru..."
    paru -S --needed --noconfirm ttf-jetbrains-mono-nerd
    postfix_scope "Checking" "AUR helper (paru)"
fi
####################################################################################

if [ "$UPDATE" = true ]; then
    prefix_scope "Checking" "repos"
    check_repo "https://github.com/sh1njiteita/snj.nvim.git" "nvim/.config/nvim"
    check_repo "https://github.com/sh1njiteita/snj.kitty.git" "kitty/.config/kitty"

    check_repo "https://github.com/sh1njiteita/snj.zsh.git" "zsh/.config/zsh"

    #####################################################################################
    prefix_scope "Post hook" "zsh"

    ZSH_TARGET_FILE="${DOTFILES_DIR}/zsh/.zshrc"

    ZSH_PARTS_PATH=${CHECK_REPO_RETURN_VALUE}
    # ZSH_PARTS_FILES=("${ZSH_PARTS_PATH}"/*.bash)
    #
    if [ -e ${ZSH_TARGET_FILE} ]; then
        rm ${ZSH_TARGET_FILE}
        touch ${ZSH_TARGET_FILE}
    fi
    #
    # for file in "${ZSH_PARTS_FILES[@]}"; do
    #     if [ -f ${file} ]; then
    #         echo "source ${file}" >>${ZSH_TARGET_FILE}
    #         echo "Added source for ${ANSI_PURPLE}${file}${ANSI_RESET}"
    #     fi
    # done

    echo "source ${ZSH_PARTS_PATH}/source.bash" >>${ZSH_TARGET_FILE}

    postfix_scope "Post hook" "zsh"
    #####################################################################################

    check_repo "https://github.com/sh1njiteita/snj.omp.git" "omp/.config/omp"
    check_repo "https://github.com/sh1njiteita/snj.tmux.git" "tmux/.config/tmux"
    check_repo "https://github.com/sh1njiteita/snj.systemd.git" "systemd/.config/systemd"

    postfix_scope "Checking" "repos"
fi
