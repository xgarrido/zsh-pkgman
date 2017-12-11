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
    pkgtools::yesno_question
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
