# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMB
# Requirements: pkgtools
# Status: not intended to be distributed yet

local cmb_pkgs=(python2 pypico cmt class planck camel)

case $(hostname) in
    cca*)
        # pkgman_install_dir=$SCRATCH_DIR/workdir/cmb/software
        sysname=${SYSNAME/*_/}
        if [[ ${sysname} = sl* ]]; then
            pkgman_install_dir=/sps/planck/camel/${sysname:u}/software
        fi
        ;;
    *)
        pkgman_install_dir=$HOME/Workdir/CMB/software
        ;;
esac

function --cmb::action()
{
    pkgtools::at_function_enter --cmb::action
    for ipkg in ${cmb_pkgs}; do
        pkgman $@ ${ipkg}
        if $(pkgtools::last_command_fails); then
            pkgtools__msg_error "Something fails when applying '$@' action to '${ipkg}'!"
            return 1
        fi
    done
    pkgtools::at_function_exit
    return 0
}

function cmb::dump()
{
    pkgtools::at_function_enter cmb::dump
    --cmb::action dump $@
    pkgtools::at_function_exit
    return 0
}

function cmb::install()
{
    pkgtools::at_function_enter cmb::install
    --cmb::action install $@
    pkgtools::at_function_exit
    return 0
}

function cmb::uninstall()
{
    pkgtools::at_function_enter cmb::uninstall
    --cmb::action uninstall $@
    pkgtools::at_function_exit
    return 0
}

function cmb::setup()
{
    pkgtools::at_function_enter cmb::setup
    if [[ ${PKGMAN_SETUP_DONE} = cmb ]]; then
        pkgtools::msg_error "CMB packages are already setup!"
        pkgtools::at_function_exit
        return 1
    elif [[ ! -z ${PKGMAN_SETUP_DONE} ]]; then
        pkgtools::msg_error "Another set of packages (${PKGMAN_SETUP_DONE}) is setup!"
        pkgtools::at_function_exit
        return 1
    fi
    --cmb::action setup $@
    pkgtools::reset_variable PKGMAN_SETUP_DONE "cmb"
    pkgtools::at_function_exit
    return 0
}

function cmb::unsetup()
{
    pkgtools::at_function_enter cmb::unsetup
    if [[ ${PKGMAN_SETUP_DONE} != cmb ]]; then
        pkgtools::msg_error "CMB packages are not setup!"
        pkgtools::at_function_exit
        return 1
    fi
   --cmb::action unsetup $@
    pkgtools::unset_variable PKGMAN_SETUP_DONE
    pkgtools::at_function_exit
    return 0
}
