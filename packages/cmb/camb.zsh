# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CAMB
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=0.1.6.1
local address="https://github.com/cmbant/CAMB/archive"
local location="${pkgman_install_dir}/camb/${version}"

function camb::dump()
{
    pkgtools::at_function_enter camb::dump
    pkgtools::msg_notice "CAMB"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
}

function camb::install()
{
    pkgtools::at_function_enter camb::install
    (
        cd $(mktemp -d)
        wget ${address}/${version}.tar.gz
        tar xzvf ${version}.tar.gz
        mkdir -p ${location}
        mv CAMB-${version}/* ${location}/.
        rm -rf $(pwd)

        pkgman setup cfitsio
        pkgman setup healpix
        cd ${location}
        sed -i -e 's#\(^FFLAGS.*\)\(-fast\)\(.*\)#\1\3#' \
            -e 's#^HEALPIXDIR.*$#HEALPIXDIR = '${HEALPIX_DIR}'#'\
            -e 's#^FITSDIR.*#FITSDIR = '${CFITSIO_LIB}"/..#" Makefile
        make all
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of CAMB software fails!"
            pkgtools::at_function_exit
            return 1
        fi
        pkgman setup python2
    )
    pkgtools::at_function_exit
    return 0
}

function camb::uninstall()
{
    pkgtools::at_function_enter camb::uninstall
    pkgtools::msg_warning "Do you really want to delete $(dirname ${location}) ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf $(dirname ${location})
    fi
    pkgtools::at_function_exit
    return 0
}

function camb::setup()
{
    pkgtools::at_function_enter camb::setup
    pkgtools::add_path_to_PATH ${location}
    pkgtools::at_function_exit
    return 0
}

function camb::unsetup()
{
    pkgtools::at_function_enter camb::unsetup
    pkgtools::remove_path_to_PATH ${location}
    pkgtools::at_function_exit
    return 0
}
