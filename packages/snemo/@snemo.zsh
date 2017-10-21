# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: SuperNEMO
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local snemo_pkgs=(brew bayeux falaise)

pkgman_install_dir=$HOME/Workdir/tmp

function --snemo::action()
{
    __pkgtools__at_function_enter --snemo::action
    for ipkg in ${snemo_pkgs}; do
        pkgman $@ ${ipkg}
    done
    __pkgtools__at_function_exit
    return 0
}

function snemo::dump()
{
    __pkgtools__at_function_enter snemo::dump
    --snemo::action dump $@
    echo "dump=$?"
    __pkgtools__at_function_exit
    return 0
}

function snemo::install()
{
    __pkgtools__at_function_enter snemo::install
    --snemo::action install $@
    __pkgtools__at_function_exit
    return 0
}

function snemo::uninstall()
{
    __pkgtools__at_function_enter snemo::uninstall
    --snemo::action uninstall $@
    __pkgtools__at_function_exit
    return 0
}

function snemo::setup()
{
    __pkgtools__at_function_enter snemo::setup
    if [[ ${PKGMAN_SETUP_DONE} = snemo ]]; then
        pkgtools__msg_error "snemo packages are already setup!"
        __pkgtools__at_function_exit
        return 1
    fi
    --snemo::action setup $@
    pkgtools__reset_variable PKGMAN_SETUP_DONE "snemo"
    __pkgtools__at_function_exit
    return 0
}

function snemo::unsetup()
{
    __pkgtools__at_function_enter snemo::unsetup
    if [[ ${PKGMAN_SETUP_DONE} != snemo ]]; then
        pkgtools__msg_error "snemo packages are not setup!"
        __pkgtools__at_function_exit
        return 1
    fi
    --snemo::action unsetup $@
    pkgtools__unset_variable PKGMAN_SETUP_DONE
    __pkgtools__at_function_exit
    return 0
}
