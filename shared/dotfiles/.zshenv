#!/bin/zsh
#            _
#    _______| |__   ___ _ ____   __
#   |_  / __| '_ \ / _ \ '_ \ \ / /
#  _ / /\__ \ | | |  __/ | | \ V /
# (_)___|___/_| |_|\___|_| |_|\_/


# Settings
export EDITOR="nvim"

# XDG Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ~/ Clean-up
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZINIT_BIN_DIR="$XDG_DATA_HOME/zinit/bin"
export LESSHISTFILE="-"

# Add to $PATH
export PATH="$PATH:$(find ~/.local/bin -maxdepth 1 -type d | paste -sd ':' -)"
