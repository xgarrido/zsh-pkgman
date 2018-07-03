# -*- mode: shell-script; -*-
#
# Copyright (C) 2018 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: healpix
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=3.40
local address="https://sourceforge.net/projects/healpix"
local location="${pkgman_install_dir}/healpix/${version}"

function healpix::dump()
{
    pkgtools::at_function_enter healpix::dump
    pkgtools::msg_notice "healpix"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " \`- from    : ${address}"
    pkgtools::at_function_exit
    return 0
}

function healpix::install()
{
    pkgtools::at_function_enter healpix::install
    (
        cd $(mktemp -d)
        wget -O healpix${version}.tar.gz https://owncloud.lal.in2p3.fr/index.php/s/P7TzIFquDwvV8pp/download
        tar xzvf healpix${version}.tar.gz
        mkdir -p ${location}
        mv Healpix_${version}/* ${location}/.
        rm -rf $(pwd)

        pkgman setup cfitsio
        cd ${location}
        cp ${pkgman_dir}/packages/cmb/patches/healpix/Makefile.template ./Makefile
        mkdir -p ${location}/../install/{lib,bin,include}
        sed -i -e 's#@HEALPIX_SRC_DIR@#'${location}'#g' Makefile
        make
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of healpix software fails!"
            pkgtools::at_function_exit
            return 1
        fi
        mkdir -p ${location}/../share
        cp -r data ${location}/../share/.
    )
    pkgtools::at_function_exit
    return 0
}

function healpix::uninstall()
{
    pkgtools::at_function_enter healpix::uninstall
    pkgtools::msg_warning "Do you really want to delete $(dirname ${location}) ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf $(dirname ${location})
    fi
    pkgtools::at_function_exit
    return 0
}

function healpix::setup()
{
    pkgtools::at_function_enter healpix::setup
    pkgtools::set_variable HEALPIX_DIR ${location}/../install
    pkgtools::set_variable HEALPIX_DATA ${HEALPIX_DIR}/data
    pkgtools::at_function_exit
    return 0
}

function healpix::unsetup()
{
    pkgtools::at_function_enter healpix::unsetup
    pkgtools::unset_variable HEALPIX_DIR
    pkgtools::unset_variable HEALPIX_DATA
    pkgtools::at_function_exit
    return 0
}
