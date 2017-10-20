# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: SuperNEMO
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local snemo_pkgs=(brew)# bayeux falaise)

pkgman_install_dir=$HOME/Workdir/tmp

function --snemo::action()
{
    __pkgtools__at_function_enter --snemo::action
    # local status=0
    for ipkg in ${snemo_pkgs}; do
        pkgman $@ ${ipkg}
        # [[ $(pkgtools__last_command_fails) ]] && status=1
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
    --snemo::action setup $@
    __pkgtools__at_function_exit
    return 0
}

function snemo::unsetup()
{
    __pkgtools__at_function_enter snemo::unsetup
    --snemo::action unsetup $@
    __pkgtools__at_function_exit
    return 0
}
