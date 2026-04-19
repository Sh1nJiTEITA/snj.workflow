#!/bin/bash


if [[ "$1" == "--debug" ]]; then
    DEBUG=true
    
    eval $(ssh-agent)
    ssh-add ~/.ssh/github

else
    DEBUG=false
fi

if [ "$DEBUG" = true ]; then
    echo "DEBUG MODE: ON"
    set -x
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
function postfix_scope { echo "$1 ${ANSI_PURPLE}$2${ANSI_RESET}... ${ANSI_BLUE}DONE${ANSI_RESET}"; echo ""; }


CHECK_REPO_RETURN_VALUE=""
function check_repo { 
	GIT_URL=$1
	NAME=$2
	ABS_PATH="${DOTFILES_DIR}/${NAME}"
	
	echo ""
	prefix_scope "Working with repo ${ANSI_BLUE}${GIT_URL}${ANSI_RESET}"

	if [ ! -d ${ABS_PATH} ]; then
		OUTPUT=$(git clone ${GIT_URL} ${ABS_PATH})
	else
		OUTPUT=$(git -C ${ABS_PATH} pull)
	fi

	echo "Endpoint path is ${ANSI_BLUE}${ABS_PATH}${ANSI_RESET}"

	echo "Ended with comment ${ANSI_YELLOW}${OUTPUT}${ANSI_RESET}"
	postfix_scope "Working with repo ${ANSI_BLUE}${GIT_URL}${ANSI_RESET}"

    CHECK_REPO_RETURN_VALUE="${ABS_PATH}"
}






DOTFILES_DIR=~/dotfiles
mkdir -p ${DOTFILES_DIR}
echo "Current dotfiles directory path is ${ANSI_BLUE}${DOTFILES_DIR}${ANSI_RESET}"



#####################################################################################
prefix_scope "Checking" "system dependencies"

check_repo "https://github.com/sh1njiteita/snj.arch_dependencies.git" "arch_dependencies"

if [ "$DEBUG" = true ]; then
    echo "Intalling system dependencies from local <dir>/PKGBUILD"
    (cd "arch_dependencies" && makepkg -sfi --noconfirm)
else 
    echo "Intalling system dependencies from repo"
    (cd "${DOTFILES_DIR}/arch_dependencies" && makepkg -si --needed --noconfirm)
fi

postfix_scope "Checking" "system dependencies"
#####################################################################################


#####################################################################################
prefix_scope "Checking" "GNU stow"

if ! command -v stow &> /dev/null; then
	prefix_scope "Installing" "GNU stow"
	sudo pacman -S --needed stow
	postfix_scope "Installing" "GNU stow"
else
	echo "GNU stow is installed"
fi

postfix_scope "Checking" "GNU stow"
#####################################################################################


#####################################################################################
prefix_scope "Checking" "oh-my-zsh"

if [ ! -d ${HOME}/.oh-my-zsh ]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else 
	echo "oh-my-zsh is installed"
fi

postfix_scope "Checking" "oh-my-zsh"
#####################################################################################


#####################################################################################
prefix_scope "Checking" "oh-my-posh"

if [ ! -d ${HOME}/.oh-my-posh ]; then
    mkdir -p ~/.oh-my-posh
	curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.oh-my-posh
else 
	echo "oh-my-posh is installed"
fi

postfix_scope "Checking" "oh-my-posh"
#####################################################################################

#####################################################################################



prefix_scope "Checking" "repos"

check_repo "https://github.com/sh1njiteita/snj.nvim.git" "nvim/.config/nvim"
check_repo "https://github.com/sh1njiteita/snj.kitty.git" "kitty/.config/kitty"


check_repo "https://github.com/sh1njiteita/snj.zsh.git" "zsh/.config/zsh"
ZSH_PARTS_PATH=${CHECK_REPO_RETURN_VALUE}
ZSH_PARTS_FILES=$( "${ZSH_PARTS_PATH}"/*.zsh )
ZSH_TARGET_FILE="${DOTFILES_DIR}/zsh/.zshrc"

echo "Post zsh hook"

if [ -e ${ZSH_TARGET_FILE} ]; then
    rm ${ZSH_TARGET_FILE}
    touch ${ZSH_TARGET_FILE}
fi

for file in "${ZSH_PARTS_FILES[@]}"; do
    if [ -f ${file} ]; then
        echo "source ${file}" >> ${ZSH_TARGET_FILE}
        echo "Added source for ${ANSI_PURPLE}${file}${ANSI_RESET}"
    fi
done






check_repo "https://github.com/sh1njiteita/snj.omp.git" "omp/.config/omp"





postfix_scope "Checking" "repos"






