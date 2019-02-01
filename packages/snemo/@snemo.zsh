# -*- mode: shell-script; -*-
#
# Copyright (C) 2017-2019 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: SuperNEMO
# Requirements: pkgtools
# Status: not intended to be distributed yet

local snemo_pkgs=(brew bayeux falaise snfee)

case $(hostname) in
    cca*)
        pkgman_install_dir=$SCRATCH_DIR/workdir/supernemo/software
        ;;
    *)
        pkgman_install_dir=$HOME/Workdir/NEMO/supernemo/software
        ;;
esac

function --snemo::action()
{
    pkgtools::at_function_enter --snemo::action
    for ipkg in ${snemo_pkgs}; do
        pkgman $@ ${ipkg}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Something fails when applying '$@' action to '${ipkg}'!"
            return 1
        fi
    done
    pkgtools::at_function_exit
    return 0
}

function snemo::dump()
{
    pkgtools::at_function_enter snemo::dump
    --snemo::action dump $@
    pkgtools::at_function_exit
    return 0
}

function snemo::install()
{
    pkgtools::at_function_enter snemo::install
    --snemo::action install $@
    pkgtools::at_function_exit
    return 0
}

function snemo::uninstall()
{
    pkgtools::at_function_enter snemo::uninstall
    --snemo::action uninstall $@
    pkgtools::at_function_exit
    return 0
}

function snemo::setup()
{
    pkgtools::at_function_enter snemo::setup
    if [[ ${PKGMAN_SETUP_DONE} = snemo ]]; then
        pkgtools::msg_error "snemo packages are already setup!"
        pkgtools::at_function_exit
        return 1
    elif [[ ! -z ${PKGMAN_SETUP_DONE} ]]; then
        pkgtools::msg_error "Another set of packages (${PKGMAN_SETUP_DONE}) is setup!"
        pkgtools::at_function_exit
        return 1
    fi
    --snemo::action setup $@
    pkgtools::reset_variable PKGMAN_SETUP_DONE "snemo"
    pkgtools::at_function_exit
    return 0
}

function snemo::unsetup()
{
    pkgtools::at_function_enter snemo::unsetup
    if [[ ${PKGMAN_SETUP_DONE} != snemo ]]; then
        pkgtools::msg_error "snemo packages are not setup!"
        pkgtools::at_function_exit
        return 1
    fi
    --snemo::action unsetup $@
    pkgtools::unset_variable PKGMAN_SETUP_DONE
    pkgtools::at_function_exit
    return 0
}
