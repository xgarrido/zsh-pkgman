# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: brew, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="https://github.com/Homebrew/brew.git"
local location="${pkgman_install_dir}/brew"

function brew::dump()
{
    pkgtools::at_function_enter brew::dump
    pkgtools::msg_notice "brew"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function brew::install()
{
    pkgtools::at_function_enter brew::install
    if [[ ! -d ${location}/.git ]]; then
        pkgtools::msg_notice "Checkout brew from ${address}"
        git clone ${address} ${location}
    fi
    brew::setup
    brew tap xgarrido/homebrew-cadfael
    brew install --build-from-source  \
         xgarrido/cadfael/root6  \
         xgarrido/cadfael/geant4 \
         xgarrido/cadfael/boost  \
         xgarrido/cadfael/camp
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Something wrongs occurs when installing brew !"
        pkgtools::at_function_exit
        return 1
    fi
    brew::unsetup
    pkgtools::at_function_exit
    return 0
}

function brew::uninstall()
{
    pkgtools::at_function_enter brew::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location} ?"
    pkgtools::yesno_question "Answer ? "
    if $(pkgtools::answer_is_yes); then
       rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function brew::setup()
{
    pkgtools::at_function_enter brew::setup
    pkgtools::add_path_to_PATH ${location}/bin
    if [[ $SHELL = *zsh* ]]; then
        fpath=($(brew --prefix)/completions/zsh $fpath)
    fi
    pkgtools::at_function_exit
    return 0
}

function brew::unsetup()
{
    pkgtools::at_function_enter brew::unsetup
    pkgtools::remove_path_to_PATH ${location}/bin
    pkgtools::at_function_exit
    return 0
}
