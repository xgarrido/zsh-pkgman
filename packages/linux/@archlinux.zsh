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

function archlinux::dump()
{
    pkgtools::at_function_enter archlinux::dump
    pkgman dump pkgs
    pkgman dump pips
    pkgtools::at_function_exit
    return 0
}

function archlinux::install()
{
    pkgtools::at_function_enter archlinux::install

    # Install pacman/yaourt packages
    pkgman install pkgs

    # Install python packages
    pkgman install pips

    # Enable services
    sudo systemctl enable cronie
    sudo systemctl enable avahi-daemon
    sudo systemctl enable sshd

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
    pkgman uninstall pkgs
    pkgman uninstall pips
    pkgtools::at_function_exit
    return 0
}
