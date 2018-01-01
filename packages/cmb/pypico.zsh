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
    pkgtools::msg_notice "pypico"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- data    : ${data}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " \`- from    : ${address}"
}

function pypico::install()
{
    (
        pkgman setup python2
        git clone ${address} ${location}
        cd ${location}
        python setup.py --build_cython build
        python setup.py --build_cython install --record installed_files.txt
        if [ ! -f ${data} ]; then
            mkdir -p $(dirname ${data})
            wget -O ${data} https://owncloud.lal.in2p3.fr/index.php/s/Q0VsmRpisQQUMKL/download
        fi
    )
}

function pypico::uninstall()
{
    pkgtools::msg_warning "Do you really want to remove pypico ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        cat ${location}/installed_files.txt | xargs rm -fr
        rm -rf ${location}
    fi
}

function pypico::setup()
{
    pkgtools::set_variable PICO_CODE ${location}
    pkgtools::set_variable PICO_DATA ${data}
}

function pypico::unsetup()
{
    pkgtools::unset_variable PICO_CODE
    pkgtools::unset_variable PICO_DATA
}
