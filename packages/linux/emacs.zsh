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
    pkgtools::at_function_enter emacs::dump
    pkgtools::at_function_exit
    return 0
}

function emacs::install()
{
    pkgtools::at_function_enter emacs::install
    local from_source=false
    if $(pkgtools::has_binary yaourt); then
        yaourt -S --noconfirm --needed emacs
    elif $(pkgtools::has_binary pacman); then
        pacman -S --noconfirm --needed emacs
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
        git get --force-https https://code.orgmode.org/bzg/org-mode.git
        if $(pkgtools::last_command_succeeds); then
            cd ~/Development/code.orgmode.org/bzg/org-mode
        else
            cd $(mktemp -d)
            git clone https://code.orgmode.org/bzg/org-mode.git
            cd org-mode
        fi
        # Add htmlize to contrib directory
        if [ ! -f contrib/lisp/htmlize.el ]; then
            wget https://raw.githubusercontent.com/hniksic/emacs-htmlize/master/htmlize.el -P contrib/lisp
        fi
        make
        sed -i -e 's/#ORG_ADD_CONTRIB.*/ORG_ADD_CONTRIB = htmlize/' local.mk
        if ${from_source}; then
            sed -i -e '/^prefix/ s#.*#prefix = '$HOME'\/.local/share#' local.mk
            make install
        else
            sudo make install
        fi
    }

    # Lambda function to install mu/mu4e
    function {
        git get https://github.com/djcb/mu
        if $(pkgtools::last_command_succeeds); then
            cd ~/Development/github.com/djcb/mu
        else
            cd $(mktemp -d)
            git clone https://github.com/djcb/mu
            cd mu
        fi
        ./autogen.sh
        make
        sudo make install
    }
    pkgtools::at_function_exit
    return 0
}
