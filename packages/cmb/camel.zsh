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
    __pkgtools__at_function_enter camel::dump
    pkgtools__msg_notice "CAMEL"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- data    : ${data}"
    pkgtools__msg_notice " |- to      : ${location}"
    pkgtools__msg_notice " \`- from    : ${address}"
    __pkgtools__at_function_exit
    return 0
}

function camel::update()
{
    __pkgtools__at_function_enter camel::update
    (
        if [[ ! -d ${location}/.git ]]; then
            pkgtools__msg_error "CAMEL is not a git repository !"
            __pkgtools__at_function_exit
            return 1
        fi
        cd ${location}
        git pull
        if $(pkgtools__last_command_fails); then
            pkgtools__msg_error "CAMEL update fails !"
            __pkgtools__at_function_exit
            return 1
        fi
    )
    __pkgtools__at_function_exit
    return 0
}

function camel::build()
{
    __pkgtools__at_function_enter camel::build
    (
        if ! $(pkgtools__check_variable CAMEL_DATA); then
            pkgtools__msg_error "CAMEL is not setup !"
            __pkgtools__at_function_exit
            return 1
        fi
        cd ${location}/cmt
        make exec
        if $(pkgtools__last_command_fails); then
            pkgtools__msg_error "CAMEL build fails !"
            __pkgtools__at_function_exit
            return 1
        fi
    )
    __pkgtools__at_function_exit
    return 0
}

function camel::install()
{
    __pkgtools__at_function_enter camel::install
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
        pkgtools__set_variable CAMEL_DATA ${data}

        git clone ${address} ${location}
        cd ${location}/cmt
        if $(pkgtools__has_binary icc); then
            rm -f requirements; ln -sf requirements-icc requirements
        elif $(pkgtools__has_binary gcc); then
            rm -f requirements; ln -sf requirements-gcc requirements
        fi
        # sed -i -e '/export PYTHONPATH=${PICO_CODE}/ s/^/#/' camel_setup.sh
        source camel_setup.sh && make && make exec
    )
    __pkgtools__at_function_exit
    return 0
}

function camel::uninstall()
{
    __pkgtools__at_function_enter camel::uninstall
    pkgtools__msg_warning "Do you really want to remove camel code @ [${location}]?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
        rm -rf ${location}
    fi
    pkgtools__msg_warning "Do you really want to remove camel data @ [${data}]?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
        rm -rf ${data}
    fi
    __pkgtools__at_function_exit
    return 0
}

function camel::setup()
{
    __pkgtools__at_function_enter camel::setup
    pkgtools__set_variable CAMEL_DATA ${data}
    pkgtools__add_path_to_PATH ${location}/Linux-x86_64

    local opwd=$PWD
    cd ${location}/cmt
    pkgtools__quietly_run "source camel_setup.sh"
    if $(pkgtools__last_command_fails); then
        cd ${opwd}
        __pkgtools__at_function_exit
        return 1
    fi
    cd ${opwd}
    __pkgtools__at_function_exit
    return 0
}

function camel::unsetup()
{
    __pkgtools__at_function_enter camel::unsetup
    pkgtools__remove_path_to_PATH ${location}/Linux-x86_64
    pkgtools__unset_variable CAMEL_DATA
    __pkgtools__at_function_exit
    return 0
}