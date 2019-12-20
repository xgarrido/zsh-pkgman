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

function dotfiles::update()
{
    pkgtools::at_function_enter dotfiles::update

    (
        if $(pkgtools::has_binary antigen); then
            pkgtools::msg_notice "Updating antigen bundles..."
            antigen update
        fi
        pkgtools::msg_notice "Updating emacs dotfiles..."
        cd ~/.emacs.d && git pull
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_warning "Can not update emacs dotfiles!"
        fi

        cd ~/Development/github.com/xgarrido
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

    # Lambda function to install emacs.d
    function {
        git clone git@github.com:xgarrido/emacs-starter-kit ~/.emacs.d
    }

    # Lambda function to install xgarrido/dotfiles
    function {
        mkdir -p ~/Development/github.com/xgarrido
        cd ~/Development/github.com/xgarrido
        git clone git@github.com:xgarrido/dotfiles
        cd dotfiles
        # Take care of keys if any
        has_keys=false
        if [ -f ~/.ssh/id_rsa ]; then
            mv ~/.ssh/id_rsa* /tmp/
            has_keys=true
        fi
        make clean
        make install
        if ${has_keys}; then
            mv /tmp/id_rsa* ~/.ssh/.
        fi
    }

    # Install add. fonts
    function {
        git clone https://github.com/pdf/ubuntu-mono-powerline-ttf.git ~/.fonts/ubuntu-mono-powerline-ttf
        git clone ttps://github.com/FortAwesome/Font-Awesome.git ~/.fonts/Font-Awesome
    }

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
        cd ~/Development/github.com/xgarrido/latex-templates
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
