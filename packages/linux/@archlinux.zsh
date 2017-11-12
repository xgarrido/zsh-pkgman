# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: archlinux
# Requirements: pkgtools
# Status: not intended to be distributed yet

if ! $(pkgtools__has_binary pacman); then
    pkgtools__msg_error "Not an archlinux distribution!"
    __pkgtools__at_function_exit
    return 1
fi

local _pkgs=(
    autofs
    bzip2
    ccache
    cmake
    dropbox
    gcc-fortran
    gdb
    go
    gparted
    imagemagick
    ncurses
    mplayer
    offlineimap
    owncloud-client
    python-pip
    rsync
    subversion
    terminator
    sshfs
    texlive-bibtexextra
    texlive-core
    texlive-fontsextra
    texlive-formatsextra
    texlive-games
    texlive-humanities
    texlive-latexextra
    texlive-music
    texlive-pictures
    texlive-pstricks
    texlive-publishers
    texlive-science
    the_silver_searcher
    tree
    ttf-adobe-fonts
    ttf-inconsolata
    ttf-ubuntu-font-family
    xclip
)

local _pips=(
    colout
    Glances
    ipython
    jupyter
    matplotlib
    meld
    numpy
    pandas
    Pygments
)

function archlinux::dump()
{
    __pkgtools__at_function_enter archlinux::dump
    pkgtools__msg_notice "Following packages will be installed:"
    pkgtools__msg_color_blue
    echo "1) via pacman/yaourt:"
    for ipkg in ${_pkgs}; do
        echo " ➜ ${ipkg}: $(yaourt -Si ${ipkg} | grep '^Version' | awk '{print $3}')"
    done
    echo "2) via pip ($(python --version)):"
    for ipip in ${_pips}; do
        echo -ne " ➜ ${ipip}"
        if $(pkgtools__has_binary pip); then
            echo ": $(pip show ${ipip} | grep '^Version' | awk '{print $2}')"
        fi
    done
    pkgtools__msg_color_normal
    __pkgtools__at_function_exit
    return 0
}

function archlinux::install()
{
    __pkgtools__at_function_enter archlinux::install

    # Lambda function for pacman/yaourt packages
    function {
        local pkg_options="-S --noconfirm --needed"
        if ! $(pkgtools__has_binary g++); then
            sudo pacman ${=pkg_options} base-devel
        fi
        if ! $(pkgtools__has_binary yaourt); then
            sudo echo "[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/$arch" >> /etc/pacman.conf
            sudo pacman ${=pkg_options} yaourt
        fi
        yaourt ${=pkg_options} $(eval print -l ${_pkgs})
    }

    # Lambda function for pip packages
    function {
        pip install -U --user $(eval print -l ${_pips})
    }

    # Install emacs
    pkgman install emacs

    __pkgtools__at_function_exit
    return 0
}

function archlinux::uninstall()
{
    __pkgtools__at_function_enter archlinux::uninstall
    pkgtools__msg_warning "Do you really want to uninstall arch packages ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
        yaourt -R $(eval print -l ${_pkgs})
    fi
    pkgtools__msg_warning "Do you really want to uninstall pip packages ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
        pip uninstall $(eval print -l ${_pips})
    fi
    __pkgtools__at_function_exit
    return 0
}
