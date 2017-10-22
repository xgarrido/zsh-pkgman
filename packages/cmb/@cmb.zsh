# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMB
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local cmb_pkgs=(python2 cmt class pypico planck camel)

case $(hostname) in
    cca*)
        pkgman_install_dir=$SCRATCH_DIR/workdir/cmb/software
        ;;
    *)
        pkgman_install_dir=$HOME/Workdir/CMB/software
        ;;
esac

function --cmb::action()
{
    __pkgtools__at_function_enter --cmb::action
    for ipkg in ${cmb_pkgs}; do
        pkgman $@ ${ipkg}
    done
    __pkgtools__at_function_exit
    return 0
}

function cmb::dump()
{
    __pkgtools__at_function_enter cmb::dump
    --cmb::action dump $@
    __pkgtools__at_function_exit
    return 0
}

function cmb::install()
{
    __pkgtools__at_function_enter cmb::install
    --cmb::action install $@
    __pkgtools__at_function_exit
    return 0
}

function cmb::uninstall()
{
    __pkgtools__at_function_enter cmb::uninstall
    --cmb::action uninstall $@
    __pkgtools__at_function_exit
    return 0
}

function cmb::setup()
{
    __pkgtools__at_function_enter cmb::setup
    if [[ ${PKGMAN_SETUP_DONE} = cmb ]]; then
        pkgtools__msg_error "CMB packages are already setup!"
        __pkgtools__at_function_exit
        return 1
    elif [[ ! -z ${PKGMAN_SETUP_DONE} ]]; then
        pkgtools__msg_error "Another set of packages (${PKGMAN_SETUP_DONE}) is setup!"
        __pkgtools__at_function_exit
        return 1
    fi
    --cmb::action setup $@
    pkgtools__reset_variable PKGMAN_SETUP_DONE "cmb"
    __pkgtools__at_function_exit
    return 0
}

function cmb::unsetup()
{
    __pkgtools__at_function_enter cmb::unsetup
    if [[ ${PKGMAN_SETUP_DONE} != cmb ]]; then
        pkgtools__msg_error "CMB packages are not setup!"
        __pkgtools__at_function_exit
        return 1
    fi
   --cmb::action unsetup $@
    pkgtools__unset_variable PKGMAN_SETUP_DONE
    __pkgtools__at_function_exit
    return 0
}
