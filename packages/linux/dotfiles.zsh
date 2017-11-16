# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: home directory
# Requirements: pkgtools
# Status: not intended to be distributed yet

function dotfiles::install()
{
    __pkgtools__at_function_enter dotfiles::install

    # Lambda function to generate ssh key
    function {
        if [[ ! -f ~/.ssh/.id_rsa.pub ]]; then
            ssh-keygen
        fi
        pkgtools__msg_warning "Do not forget to copy the ssh key to github.com!"
    }

    # Lambda function to install xgarrido/dotfiles
    function {
        mkdir -p ~/Development/github.com/xgarrido
        cd ~/Development/github.com/xgarrido
        git clone git@github.com:xgarrido/dotfiles
        cd dotfiles
        make clean
        make install
    }

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
        if ! $(pkgtools__has_binary emacs); then
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
    __pkgtools__at_function_exit
    return 0
}
