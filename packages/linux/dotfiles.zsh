# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: home directory
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=null
function dotfiles::install()
{
    pkgtools::at_function_enter dotfiles::install

    # Lambda function to install emacs.d
    function {
        cd ~
        rm -rf .emacs.d
        git clone git@github.com:xgarrido/emacs-starter-kit .emacs.d
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

    # Make sure ~/.bin is in the PATH
    pkgtools::add_path_to_PATH $HOME/.bin

    # Clone github repositories
    local githubs=(
        artist
        d3-change.org
        latex-templates
        org-book
        org-life
        org-notes
        org-resume
        org-web-links
        org-website
        pygments-styles
        tikz-figures
    )
    for igit in ${githubs}; do
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
        cd $TEXMFHOME/tex/latex/commonstuff
        if [[ ! -f font-awesomesty ]]; then
            wget \
                https://gist.githubusercontent.com/xgarrido/b4176717a24c530ed3f309c46c38fc5a/raw/0016c76e532b55d5802aefad248b39472776420c/font-awesome.sty
        fi
        pip install --user pygments-style-solarized
    }

    # Install go packages
    function {
        go get -u github.com/sbinet/go-svn2git
        go get -u github.com/junegunn/fzf
    }
    pkgtools::at_function_exit
    return 0
}
