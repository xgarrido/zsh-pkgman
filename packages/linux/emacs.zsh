# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: emacs
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=25.3
local address="http://mirror.ibcp.fr/pub/gnu/emacs/emacs-${version}.tar.gz"

function emacs::dump()
{
    __pkgtools__at_function_enter emacs::dump
    __pkgtools__at_function_exit
    return 0
}

function emacs::install()
{
    __pkgtools__at_function_enter emacs::install
    local from_source=false
    if $(pkgtools__has_binary yaourt); then
        yaourt -S --noconfirm --needed emacs
    elif $(pkgtools__has_binary pacman); then
        pacmane -S --noconfirm --needed emacs
    else
        (
            cd $(mktemp -d)
            wget ${address}
            tar xzvf emacs-${version}.tar.gz
            cd emacs-${version}
            ./configure --prefix ~/.local && make && make install
        )
        from_source=true
    fi

    # Make sure .profile has been setup
    source ~/.profile

    # Lambda function to install org-mode
    function {
        git get git://orgmode.org/org-mode.git
        if $(pkgtools__last_command_succeeds); then
            cd ~/Development/org-mode
        else
            cd $(mktemp -d)
            git clone git://orgmode.org/org-mode.git
        fi
        if ${from_source}; then
            sed -i -e '/^prefix/ s/.*/prefix = '$HOME'\/.local/share' local.mk
            make install
        else
            sudo make install
        fi
    }

    # Lambda function to install mu/mu4e
    function {
        git get https://github.com/djcb/mu
        if $(pkgtools__last_command_succeeds); then
            cd ~/Development/org-mode
        else
            cd $(mktemp -d)
            git clone https://github.com/djcb/mu
        fi
        sudo make install
    }
    __pkgtools__at_function_exit
    return 0
}
