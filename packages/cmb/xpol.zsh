# -*- mode: shell-script; -*-
#
# Copyright (C) 2018 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: xpol
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="git@gitlab.in2p3.fr:tristram/Xpol.git"
local location="${pkgman_install_dir}/xpol/${version}"

function xpol::dump()
{
    pkgtools::at_function_enter xpol::dump
    pkgtools::msg_notice "xpol"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function xpol::install()
{
    pkgtools::at_function_enter xpol::install
    if ! $(cmb::at_cc); then
        pkgtools::msg_warning "Xpol can not be installed other than at CC!"
        pkgtools::at_function_exit
        return 1
    fi
    (
        git clone ${address} ${location}
        cd ${location}
        cp ${pkgman_dir}/packages/cmb/patches/xpol/Makefile.template ./Makefile
        if ! $(pkgtools::has_binary mpif90); then
            pkgtools::msg_error "Missing mpi binaries!"
            pkgtools::at_function_exit
            return 1
        fi
        pkgman setup s2hat
        pkgman setup healpix
        pkgman setup cfitsio

        make
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of Xpol fails!"
            pkgtools::at_function_exit
            return 1
        fi

        pkgman setup python2
        python setup.py install --prefix=${VIRTUAL_ENV}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of Xpol python library fails!"
            pkgtools::at_function_exit
            return 1
        fi
    )
    pkgtools::at_function_exit
    return 0
}

function xpol::uninstall()
{
    pkgtools::at_function_enter xpol::uninstall
    pkgtools::msg_warning "Do you really want to remove xpol ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function xpol::setup()
{
    pkgtools::at_function_enter xpol::setup
    pkgtools::add_path_to_PATH ${location}/../install/bin
    pkgtools::at_function_exit
    return 0
}

function xpol::unsetup()
{
    pkgtools::at_function_enter xpol::unsetup
    pkgtools::remove_path_to_PATH ${location}/../install/bin
    pkgtools::at_function_exit
    return 0
}
