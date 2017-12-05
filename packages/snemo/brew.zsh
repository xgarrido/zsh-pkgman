# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: brew, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="https://github.com/SuperNEMO-DBD/brew.git"
local location="${pkgman_install_dir}/brew"

function brew::dump()
{
    __pkgtools__at_function_enter brew::dump
    pkgtools__msg_notice "brew"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- from    : ${address}"
    pkgtools__msg_notice " \`- to      : ${location}"
    __pkgtools__at_function_exit
    return 0
}

function brew::install()
{
    __pkgtools__at_function_enter brew::install
    if [[ ! -d ${location}/.git ]]; then
        pkgtools__msg_notice "Checkout brew from ${address}"
        git clone ${address} ${location}
    fi
    local gcc_version=$(g++ --version | head -1 | awk '{print $3}')
    if [[ $(hostname) = cca* ]]; then
        ln -sf $(which g++) ${location}/bin/g++-${gcc_version:0:1}
        ln -sf $(which gcc) ${location}/bin/gcc-${gcc_version:0:1}
    fi
    if [[ ${gcc_version} > 6 ]]; then
        (
            cd ${location}/Library/Homebrew/shims/linux/super
            local main_version=${gcc_version[1]}
            if [[ ! -f  gcc-${main_version} && ! -f g++-${main_version} ]]; then
                ln -sf cc gcc-${main_version} && git add gcc-${main_version}
                ln -sf cc g++-${main_version} && git add g++-${main_version}
                git commit -m "add gcc/g++ 7"
            fi
        )
    fi
    brew::setup
    brew install --build-from-source  \
         supernemo-dbd/cadfael/root6  \
         supernemo-dbd/cadfael/geant4 \
         supernemo-dbd/cadfael/boost  \
         supernemo-dbd/cadfael/camp
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Something wrongs occurs when installing brew !"
        __pkgtools__at_function_exit
        return 1
    fi
    brew::unsetup
    __pkgtools__at_function_exit
    return 0
}

function brew::uninstall()
{
    __pkgtools__at_function_enter brew::uninstall
    pkgtools__msg_warning "Do you really want to delete ${location} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}
    fi
    __pkgtools__at_function_exit
    return 0
}

function brew::setup()
{
    __pkgtools__at_function_enter brew::setup
    pkgtools__add_path_to_PATH ${location}/bin
    __pkgtools__at_function_exit
    return 0
}

function brew::unsetup()
{
    __pkgtools__at_function_enter brew::unsetup
    pkgtools__remove_path_to_PATH ${location}/bin
    __pkgtools__at_function_exit
    return 0
}
