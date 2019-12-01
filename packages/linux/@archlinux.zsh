# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: archlinux
# Requirements: pkgtools
# Status: not intended to be distributed yet

if ! $(pkgtools::has_binary pacman); then
    pkgtools::msg_error "Not an archlinux distribution!"
    pkgtools::at_function_exit
    return 1
fi

local _pkgs=(
    acpi
    autofs
    bat
    bzip2
    cblas
    ccache
    cmake
    cronie
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
    jq
    lapack
    lxappearance
    meld
    mplayer
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
    ttf-adobe-fonts
    ttf-inconsolata
    ttf-ubuntu-font-family
    xapian-core
    xclip
    xdotool
    wmctrl
)

local _pips=(
    glances
    camb
    cobaya
    cython
    ipython
    jupyter
    jupyter-repo2docker
    numpy
    matplotlib
    pandas
    seaborn
    scipy
    pipenv
    pygments
    pyyaml
)

function archlinux::dump()
{
    pkgtools::at_function_enter archlinux::dump
    pkgtools::msg_notice "Following packages will be installed:"
    pkgtools::msg_color_blue
    echo "1) via pacman/yaourt:"
    for ipkg in ${_pkgs}; do
        echo " ➜ ${ipkg}: $(yaourt -Si ${ipkg} | grep '^Version' | awk '{print $3}')"
    done
    echo "2) via pip ($(python --version)):"
    for ipip in ${_pips}; do
        echo -ne " ➜ ${ipip}"
        if $(pkgtools::has_binary pip); then
            echo ": $(pip show ${ipip} | grep '^Version' | awk '{print $2}')"
        fi
    done
    pkgtools::msg_color_normal
    pkgtools::at_function_exit
    return 0
}

function archlinux::install()
{
    pkgtools::at_function_enter archlinux::install

    # Lambda function for pacman/yaourt packages
    function {
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
            yaourt ${=pkg_options} ${ipkg}
        done
    }

    # Lambda function for pip packages
    function {
        for ipip in ${_pips}; do
            pip install --upgrade --user ${ipip}
        done
        # Fix for colout
        pip install --user git+https://github.com/nojhan/colout.git
    }

    # Enable services
    sudo systemctl enable cronie

    # Install home setup
    pkgman install dotfiles

    # Install emacs
    pkgman install emacs

    pkgtools::at_function_exit
    return 0
}

function archlinux::uninstall()
{
    pkgtools::at_function_enter archlinux::uninstall
    pkgtools::msg_warning "Do you really want to uninstall arch packages ?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        yaourt -R $(eval print -l ${_pkgs})
    fi
    pkgtools::msg_warning "Do you really want to uninstall pip packages ?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        pip uninstall $(eval print -l ${_pips})
    fi
    pkgtools::at_function_exit
    return 0
}
