# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: cfitsio
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=3.450
local address="http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/"
local location="${pkgman_install_dir}/cfitsio/${version}"

function cfitsio::dump()
{
    pkgtools::at_function_enter cfitsio::dump
    pkgtools::msg_notice "cfitsio"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function cfitsio::install()
{
    pkgtools::at_function_enter cfitsio::install
    (
        cd $(mktemp -d)
        wget ${address}/cfitsio${version/./}.tar.gz
        tar xzvf cfitsio${version/./}.tar.gz
        mkdir -p ${location}
        mv cfitsio/* ${location}/.
        rm -rf $(pwd)

        cd ${location}
        ./configure --prefix=${location}/../install && make && make shared && make install
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of cfitsio software fails!"
            pkgtools::at_function_exit
            return 1
        fi
    )
    pkgtools::at_function_exit
    return 0
}

function cfitsio::uninstall()
{
    pkgtools::at_function_enter cfitsio::uninstall
    pkgtools::msg_warning "Do you really want to delete $(dirname ${location}) ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf $(dirname ${location})
    fi
    pkgtools::at_function_exit
    return 0
}

function cfitsio::setup()
{
    pkgtools::at_function_enter cfitsio::setup
    pkgtools::set_variable CFITSIO_INCLUDE ${location}/../install/include
    pkgtools::set_variable CFITSIO_LIB ${location}/../install/lib
    pkgtools::at_function_exit
    return 0
}

function cfitsio::unsetup()
{
    pkgtools::at_function_enter cfitsio::unsetup
    pkgtools::unset_variable CFITSIO_INCLUDE
    pkgtools::unset_variable CFITSIO_LIB
    pkgtools::at_function_exit
    return 0
}
