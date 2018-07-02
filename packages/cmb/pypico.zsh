# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: pypico
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="https://github.com/marius311/pypico"
local location="${pkgman_install_dir}/pypico/${version}"
local data="${pkgman_install_dir}/../data/pico_data/pico3_tailmonty_v34.dat"

function pypico::dump()
{
    pkgtools::at_function_enter pypico::dump
    pkgtools::msg_notice "pypico"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " \`- data    : ${data}"
    pkgtools::at_function_exit
    return 0
}

function pypico::install()
{
    pkgtools::at_function_enter pypico::install
    (
        pkgman setup python2
        git clone ${address} ${location}
        cd ${location}
        python setup.py --build_cython build
        python setup.py --build_cython install --record installed_files.txt
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of pypico fails!"
            pkgtools::at_function_exit
            return 1
        fi

        if [ ! -f ${data} ]; then
            mkdir -p $(dirname ${data})
            wget -O ${data} https://owncloud.lal.in2p3.fr/index.php/s/Q0VsmRpisQQUMKL/download
        fi
    )
    pkgtools::at_function_exit
    return 0
}

function pypico::uninstall()
{
    pkgtools::at_function_enter pypico::uninstall
    pkgtools::msg_warning "Do you really want to remove pypico ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        cat ${location}/installed_files.txt | xargs rm -fr
        rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function pypico::setup()
{
    pkgtools::at_function_enter pypico::setup
    pkgtools::set_variable PICO_CODE ${location}
    pkgtools::set_variable PICO_DATA ${data}
    pkgtools::at_function_exit
    return 0
}

function pypico::unsetup()
{
    pkgtools::at_function_enter pypico::unsetup
    pkgtools::unset_variable PICO_CODE
    pkgtools::unset_variable PICO_DATA
    pkgtools::at_function_exit
    return 0
}
