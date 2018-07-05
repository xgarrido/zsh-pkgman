# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CLASS
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=v2.4.4
local address="https://github.com/lesgourg/class_public/archive"
local location="${pkgman_install_dir}/class/${version}"

function class::dump()
{
    pkgtools::at_function_enter class::dump
    pkgtools::msg_notice "class"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function class::install()
{
    pkgtools::at_function_enter class::install
    (
        pkgman setup cmt
        cd $(mktemp -d)
        wget ${address}/${version}.tar.gz
        tar xzvf ${version}.tar.gz
        mkdir -p ${location}
        mv class_public-${version/v/}/* ${location}/.
        rm -rf $(pwd)

        cd ${location}/../..
        cmt create class ${version}
        cd ${location}/cmt
        if $(pkgtools::has_binary icc); then
            [[ ! -f requirements-class-icc.txt ]] && \
                wget http://camel.in2p3.fr/wiki/uploads/Main/requirements-class-icc.txt
            sed -i -e 's#-openmp#-qopenmp -qoverride-limits#' requirements-class-icc.txt
            sed -i -e 's#/afs/in2p3.fr/.*-liomp5#'$(dirname $(which icc))'/../../lib/intel64 -liomp5#' requirements-class-icc.txt
            rm -f requirements; ln -sf requirements-class-icc.txt requirements
        elif $(pkgtools::has_binary gcc); then
            [[ ! -f requirements-class-gcc.txt ]] && \
                wget http://camel.in2p3.fr/wiki/uploads/Main/requirements-class-gcc.txt
            rm -f requirements; ln -sf requirements-class-gcc.txt requirements
        fi
        cmt config
        make
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of class fails!"
            pkgtools::at_function_exit
            return 1
        fi
        cd ${location}/..
        ln -sf ${version} HEAD
    )
    pkgtools::at_function_exit
    return 0
}

function class::uninstall()
{
    pkgtools::at_function_enter class::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location} ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function class::setup()
{
    pkgtools::at_function_enter class::setup
    pkgtools::msg_notice -n "Configuring CLASS..."
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::set_variable CMTCLASS ${pkgman_install_dir}
    pkgtools::at_function_exit
    return 0
}

function class::unsetup()
{
    pkgtools::at_function_enter class::unsetup
    pkgtools::msg_notice -n "Unconfiguring CLASS..."
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::unset_variable CMTCLASS
    pkgtools::at_function_exit
    return 0
}
