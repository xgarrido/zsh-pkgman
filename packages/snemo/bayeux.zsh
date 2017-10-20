# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: bayeux, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="git@github.com:BxCppDev/Bayeux.git"
local location="${pkgman_install_dir}/bayeux"

function bayeux::dump()
{
    __pkgtools__at_function_enter bayeux::dump
    pkgtools__msg_notice "bayeux"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- from    : ${address}"
    pkgtools__msg_notice " \`- to      : ${location}"
    __pkgtools__at_function_exit
    return 0
}

function bayeux::configure()
{
    __pkgtools__at_function_enter bayeux::configure

    pkgman setup brew
    local bayeux_options="
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INSTALL_PREFIX=${location}/install
        -DCMAKE_PREFIX_PATH=$(dirname $(pkgtools__get_binary_path brew))/..
        -DBAYEUX_CXX_STANDARD=14 "
    while [ -n "$1" ]; do
        local token="$1"
        if [[ ${token[0,1]} = - ]]; then
            local opt=${token}
            if [[ ${opt} = --with-test ]]; then
                bayeux_options+="-DBAYEUX_ENABLE_TESTING=ON "
            elif [[ ${opt} = --without-test ]]; then
                bayeux_options+="-DBAYEUX_ENABLE_TESTING=OFF "
            elif [[ ${opt} = --with-doc ]]; then
                bayeux_options+="-DBAYEUX_WITH_DOCS=ON "
            elif [[ ${opt} = --without-doc ]]; then
                bayeux_options+="-DBAYEUX_WITH_DOCS=OFF "
            elif [[ ${opt} = --with-warning ]]; then
                bayeux_options+="-DBAYEUX_COMPILER_ERROR_ON_WARNING=ON "
            elif [[ ${opt} = --without-warning ]]; then
                bayeux_options+="-DBAYEUX_COMPILER_ERROR_ON_WARNING=OFF "
            fi
        fi
        shift 1
    done
    pkgtools__msg_devel "bayeux_options=${bayeux_options}"

    if $(pkgtools__has_binary ninja); then
        bayeux_options+="-G Ninja -DCMAKE_MAKE_PROGRAM=$(pkgtools__get_binary_path ninja)"
    fi

    local ret=0
    pkgtools__enter_directory ${location}/build
    cmake $(echo ${bayeux_options}) ${location}/${version}
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Configuration of bayeux fails!"
        ret=1
    fi
    pkgtools__exit_directory
    pkgman unsetup brew
    __pkgtools__at_function_exit
    return ${ret}
}

function bayeux::install()
{
    __pkgtools__at_function_enter bayeux::install
    (
        if [[ ! -d ${location}/${version}/.git ]]; then
            pkgtools__msg_notice "Checkout brew from ${address}"
            git clone ${address} ${location}/${version}
        fi
        bayeux::configure $@
    )
    __pkgtools__at_function_exit
    return 0
}

function bayeux::uninstall()
{
    __pkgtools__at_function_enter bayeux::uninstall
    pkgtools__msg_warning "Do you really want to delete ${location}/{build,install} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}/{build,install}
    fi
    __pkgtools__at_function_exit
    return 0
}

function bayeux::setup()
{
    __pkgtools__at_function_enter bayeux::setup
    pkgtools__add_path_to_PATH ${location}/install/bin
    __pkgtools__at_function_exit
    return 0
}

function bayeux::unsetup()
{
    __pkgtools__at_function_enter bayeux::unsetup
    pkgtools__remove_path_to_PATH ${location}/install/bin
    __pkgtools__at_function_exit
    return 0
}
