# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: s2hat
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=v2.55beta
local address="http://www.apc.univ-paris7.fr/APC_CS/Recherche/Adamis/MIDAS09/software/s2hat/s2hat/software/"
local location="${pkgman_install_dir}/s2hat/${version}"

function s2hat::dump()
{
    pkgtools::at_function_enter s2hat::dump
    pkgtools::msg_notice "s2hat"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function s2hat::install()
{
    pkgtools::at_function_enter s2hat::install
    if ! $(cmb::at_cc); then
        pkgtools::msg_warning "s²hat can not be installed other than at CC!"
        pkgtools::at_function_exit
        return 1
    fi
    (
        cd $(mktemp -d)
        wget ${address}/s2hat_${version}_30april2012.tar.gz
        tar xzvf s2hat_${version}_30april2012.tar.gz
        mkdir -p ${location}
        mv * ${location}/.
        rm ${location}/s2hat_${version}_30april2012.tar.gz
        rm -rf $(pwd)

        pkgman setup healpix
        cd ${location}
        chmod u+r *; chmod g+w *
        cp ${pkgman_dir}/packages/cmb/patches/s2hat/Makefile.template ./Makefile
        # Special binaries mpif90 and mpicc for s2hat
        pkgtools::add_path_to_PATH /usr/local/intel/2018/compilers_and_libraries/linux/mpi/intel64/bin
        make
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of s²hat softawre fails!"
            pkgtools::at_function_exit
            return 1
        fi
        ln -sf libs2hat_hlpx_g.a libs2hat.a
    )
    pkgtools::at_function_exit
    return 0
}

function s2hat::uninstall()
{
    pkgtools::at_function_enter s2hat::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location} ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf $(dirname ${location})
    fi
    pkgtools::at_function_exit
    return 0
}

function s2hat::setup()
{
    pkgtools::at_function_enter s2hat::setup
    pkgtools::set_variable S2HAT_DIR ${location}
    pkgtools::at_function_exit
    return 0
}

function s2hat::unsetup()
{
    pkgtools::at_function_enter s2hat::unsetup
    pkgtools::unset_variable S2HAT_DIR
    pkgtools::at_function_exit
    return 0
}
