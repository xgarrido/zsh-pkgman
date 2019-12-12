# -*- mode: shell-script; -*-
#
# Copyright (C) 2019 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: archlinux
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=null
local _pkgs=(
    arc-gtk-theme
    acpi
    autofs
    bat
    bzip2
    cblas
    ccache
    chromium
    cmake
    cronie
    dmenu
    docker
    dropbox
    dunst
    freerdp
    gcc-fortran
    gdb
    gnuplot
    go
    gparted
    gmime
    hsetroot
    imagemagick
    inetutils
    jq
    lapack
    lxappearance
    meld
    mplayer
    net-tools
    ncurses
    ninja
    offlineimap
    openbox
    owncloud-client
    perl-term-readkey
    python-pip
    pstoedit
    remmina
    ruby
    ruby-irb
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
    tk
    the_silver_searcher
    tree
    ttf-adobe-source-fonts
    ttf-inconsolata
    ttf-ubuntu-font-family
    xapian-core
    xclip
    xdotool
    xorg-xrandr
    wmctrl
)

function pkgs::dump()
{
    pkgtools::at_function_enter pkgs::dump
    for ipkg in ${_pkgs}; do
        echo " ➜ ${ipkg}: $(yaourt -Si ${ipkg} | grep '^Version' | awk '{print $3}')"
    done
    pkgtools::at_function_exit
    return 0
}

function pkgs::install()
{
    pkgtools::at_function_enter pkgs::install
    local pkg_options="-S --noconfirm --needed"
    if ! $(pkgtools::has_binary g++); then
        sudo pacman ${=pkg_options} base-devel
    fi
    if ! $(pkgtools::has_binary git); then
        sudo pacman ${=pkg_options} git
    fi
    if ! $(pkgtools::has_binary yaourt); then
        (
            cd $(mktemp -d)
            git clone https://aur.archlinux.org/package-query.git
            cd package-query
            makepkg -si --noconfirm
            cd ..
            git clone https://aur.archlinux.org/yaourt.git
            cd yaourt
            makepkg -si --noconfirm
            cd ..
            rm -rf $(pwd)
        )
    fi
    for ipkg in ${_pkgs}; do
        pkgtools::msg_notice "Installing '${ipkg}' via yaourt..."
        yaourt ${=pkg_options} ${ipkg}
    done
    pkgtools::at_function_exit
    return 0
}

function pkgs::uninstall()
{
    pkgtools::at_function_enter pkgs::uninstall
    pkgtools::msg_warning "Do you really want to uninstall arch packages ?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        yaourt -R $(eval print -l ${_pkgs})
    fi
    pkgtools::at_function_exit
    return 0
}
