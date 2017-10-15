# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMT
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=v2.6.1
local address="https://github.com/lesgourg/class_public"
local location="${pkgman_install_dir}/class/${version}"

function class::dump()
{
    pkgtools__msg_notice "CLASS"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- from    : ${address}"
    pkgtools__msg_notice " \`- to      : ${location}"
}

function class::install()
{
    (
        pkgman setup cmt
        git clone -b ${version} ${address} ${location}
        cd ${location}/../..
        cmt create class ${version}
        cd ${location}/cmt
        if $(pkgtools__has_binary icc); then
            wget http://camel.in2p3.fr/wiki/uploads/Main/requirements-class-icc.txt
            rm -f requirements; ln -sf requirements-class-icc.txt requirements
        elif $(pkgtools__has_binary gcc); then
            wget http://camel.in2p3.fr/wiki/uploads/Main/requirements-class-gcc.txt
            rm -f requirements; ln -sf requirements-class-gcc.txt requirements
        fi
        cmt config
        make
        cd ${location}/..
        ln -sf ${version} HEAD
    )
}

function class::uninstall()
{
    pkgtools__msg_warning "Do you really want to delete ${location} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}
    fi
}

function class::setup()
{
    pkgtools__set_variable CMTCLASS ${pkgman_install_dir}
}

function class::unsetup()
{
    pkgtools__unset_variable CMTCLASS
}
