# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CAMEL
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=HEAD
local address="git@gitlab.in2p3.fr:xgarrido/CAMEL.git"
local location="${pkgman_install_dir}/CAMEL/${version}"
local data="${pkgman_install_dir}/../data/camel_data"

function camel::dump()
{
    pkgtools::at_function_enter camel::dump
    pkgtools::msg_notice "CAMEL"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- data    : ${data}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " \`- from    : ${address}"
    pkgtools::at_function_exit
    return 0
}

function camel::update()
{
    pkgtools::at_function_enter camel::update
    if [[ ! -d ${location}/.git ]]; then
        pkgtools::msg_error "CAMEL is not a git repository !"
        pkgtools::at_function_exit
        return 1
    fi
    git --git-dir=${location}/.git --work-tree=${location} pull
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "CAMEL update fails !"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function camel::build()
{
    pkgtools::at_function_enter camel::build
    if ! $(pkgtools::check_variable CAMEL_DATA); then
        pkgtools::msg_error "CAMEL is not setup !"
        pkgtools::at_function_exit
        return 1
    fi
    make -C ${location}/cmt exec
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "CAMEL build fails !"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function camel::install()
{
    pkgtools::at_function_enter camel::install
    (
        pkgman setup python2
        pkgman setup cmt
        pkgman setup class
        pkgman setup planck
        pkgman setup pypico
        if [ ! -d ${data} ]; then
            mkdir -p ${data}; cd ${data}/..
            wget http://camel.in2p3.fr/data/camel_data.tar
            tar -xvf camel_data.tar
            rm -rf camel_data.tar
        fi
        pkgtools::set_variable CAMEL_DATA ${data}

        git clone ${address} ${location}
        cd ${location}/cmt
        if $(pkgtools::has_binary icc); then
            rm -f requirements; ln -sf requirements-icc requirements
        elif $(pkgtools::has_binary gcc); then
            rm -f requirements; ln -sf requirements-gcc requirements
        fi
        # sed -i -e '/export PYTHONPATH=${PICO_CODE}/ s/^/#/' camel_setup.sh
        source camel_setup.sh && make && make exec
    )
    pkgtools::at_function_exit
    return 0
}

function camel::uninstall()
{
    pkgtools::at_function_enter camel::uninstall
    pkgtools::msg_warning "Do you really want to remove camel code @ [${location}]?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        rm -rf ${location}
    fi
    pkgtools::msg_warning "Do you really want to remove camel data @ [${data}]?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        rm -rf ${data}
    fi
    pkgtools::at_function_exit
    return 0
}

function camel::setup()
{
    pkgtools::at_function_enter camel::setup
    pkgtools::set_variable CAMEL_DATA ${data}
    pkgtools::add_path_to_PATH ${location}/Linux-x86_64

    local ret=0
    pkgtools::enter_directory ${location}/cmt
    source camel_setup.sh
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Something fails when sourcing camel setup!"
        ret=1
    fi
    pkgtools::exit_directory
    pkgtools::at_function_exit
    return ${ret}
}

function camel::unsetup()
{
    pkgtools::at_function_enter camel::unsetup
    pkgtools::remove_path_to_PATH ${location}/Linux-x86_64
    pkgtools::unset_variable CAMEL_DATA
    pkgtools::at_function_exit
    return 0
}
