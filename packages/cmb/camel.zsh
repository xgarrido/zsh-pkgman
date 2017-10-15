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
    pkgtools__msg_notice "CAMEL"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- data    : ${data}"
    pkgtools__msg_notice " |- to      : ${location}"
    pkgtools__msg_notice " \`- from    : ${address}"
}

function camel::install()
{
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
        sed -i -e '/export PYTHONPATH=${PICO_CODE}/ s/^/#/' camel_setup.sh
        source camel_setup.sh && make && make exec
    )
}

function camel::uninstall()
{
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
}

function camel::setup()
{
    local opwd=$(pwd)
    cd ${location}/cmt
    pkgtools__quietly_run "source camel_setup.sh"
    cd ${opwd}

    pkgtools__add_path_to_PATH ${location}/Linux-x86_64
    pkgtools__set_variable CAMEL_DATA ${data}
}

function camel::unsetup()
{
    pkgtools__remove_path_to_PATH ${location}/Linux-x86_64
    pkgtools__unset_variable CAMEL_DATA
}
