# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: home directory
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=null
local _githubs=(
    artist
    d3-change.org
    dockerfiles
    install_archlinux
    latex-templates
    org-book
    org-life
    org-notes
    org-resume
    org-web-links
    org-website
    pygments-styles
    tikz-figures
    xgarrido.github.io
)

pkgtools::reset_variable GIT_GET_DIRECTORY ${HOME}/Development

function dotfiles::update()
{
    pkgtools::at_function_enter dotfiles::update

    (
        pkgtools::msg_notice "Updating emacs dotfiles..."
        cd ~/.emacs.d && git pull
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_warning "Can not update emacs dotfiles!"
        fi

        cd ${GIT_GET_DIRECTORY}/github.com/xgarrido
        for igit in ${_githubs}; do
            (
                pkgtools::msg_notice "Updating '${igit}'..."
                cd ${igit} && git pull
                if $(pkgtools::last_command_fails); then
                    pkgtools::msg_warning "Can not update ${igit} dotfiles!"
                fi
            )
        done
    )

    pkgtools::at_function_exit
    return 0
}

function dotfiles::install()
{
    pkgtools::at_function_enter dotfiles::install

    # Make sure ~/.bin is in the PATH
    pkgtools::add_path_to_PATH $HOME/.bin

    # Clone github repositories
    for igit in ${_githubs}; do
        git get github.com/xgarrido/${igit}
    done

    # Install LaTeX styles files
    function {
        # Make sure emacs has been already installed otherwise do it
        if ! $(pkgtools::has_binary emacs); then
            pkgman install emacs
        fi
        cd ${GIT_GET_DIRECTORY}/github.com/xgarrido/latex-templates
        make
    }

    # Install go packages
    function {
        pkgtools::reset_variable GOPATH ${HOME}/Development/go
        go get -u github.com/sbinet/go-svn2git
        go get -u github.com/junegunn/fzf
    }
    pkgtools::at_function_exit
    return 0
}
