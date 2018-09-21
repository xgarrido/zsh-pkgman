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
    (
        cd ${location}/cmt
        make clean && rm -rf ../$CMTCONFIG && make && make exec
    )
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

        git clone ${address} ${location} || \
            git clone ${address/git@gitlab.in2p3.fr:/https:\/\/gitlab.in2p3.fr\/} ${location}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "git clone fails!"
            pkgtools::at_function_exit
            return 1
        fi
        cd ${location}
        git remote add upstream git@gitlab.in2p3.fr:cosmotools/CAMEL.git
        cd ${location}/cmt
        rm -f requirements
        if $(pkgtools::has_binary icc); then
            cp ${pkgman_dir}/packages/cmb/patches/camel/requirements-icc ./requirements-pkgman
        elif $(pkgtools::has_binary gcc); then
            cp ${pkgman_dir}/packages/cmb/patches/camel/requirements-gcc ./requirements-pkgman
        fi
        ln -sf requirements-pkgman requirements

        cp ${pkgman_dir}/packages/cmb/patches/camel/pkgman_setup.sh .
        source pkgman_setup.sh && make && make exec
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of CAMEL software fails!"
            pkgtools::at_function_exit
            return 1
        fi

        pkgman setup python2
        cd ${location}/work/tools/python
        pip install -e .
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of Python library for CAMEL fails!"
            pkgtools::at_function_exit
            return 1
        fi
    )
    pkgtools::at_function_exit
    return 0
}

function camel::uninstall()
{
    pkgtools::at_function_enter camel::uninstall
    pkgtools::msg_warning "Do you really want to remove camel code @ [${location}]?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf ${location}
    fi
    pkgtools::msg_warning "Do you really want to remove camel data @ [${data}]?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf ${data}
    fi
    pkgtools::at_function_exit
    return 0
}

function camel::test()
{
    pkgtools::at_function_enter camel::test
    (
        camel::setup
        pkgtools::msg_notice "Testing CAMEL..."
        cd ${location}/cmt
        make test
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Making test for CAMEL fails!"
            pkgtools::at_function_exit
            return 1
        fi
        cd $(mktemp -d)
        local tests=(testKlass)
        for f in ${tests}; do
            pkgtools::msg_notice "Testing ${f}..."
            eval ${f}
            if $(pkgtools::last_command_fails); then
                pkgtools::msg_error "Testing ${f} fails!"
                pkgtools::at_function_exit
                return 1
            fi
        done
        rm -rf $(pwd)
        pkgtools::msg_notice "All tests passed!"
    )
    pkgtools::at_function_exit
    return 0
}

function camel::setup()
{
    pkgtools::at_function_enter camel::setup
    pkgtools::msg_notice -n "Configuring CAMEL..."
    pkgtools::set_variable CAMEL_DATA ${data}
    pkgtools::add_path_to_PATH ${location}/Linux-x86_64

    pkgtools::enter_directory ${location}/cmt
    source pkgman_setup.sh > /tmp/camel.log 2>&1
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_color_red; echo "\033[3D ➜ error"; pkgtools::msg_color_normal
        pkgtools::msg_error "Something fails when sourcing camel setup!"
        pkgtools::msg_error "Dump logfile:"; cat /tmp/camel.log
        pkgtools::exit_directory
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::exit_directory
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::at_function_exit
    return 0
}

function camel::unsetup()
{
    pkgtools::at_function_enter camel::unsetup
    pkgtools::msg_notice -n "Unconfiguring CAMEL..."
    pkgtools::remove_path_to_PATH ${location}/Linux-x86_64
    pkgtools::unset_variable CAMEL_DATA
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::at_function_exit
    return 0
}
