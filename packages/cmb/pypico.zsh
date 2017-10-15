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
    pkgtools__msg_notice "pypico"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- data    : ${data}"
    pkgtools__msg_notice " |- to      : ${location}"
    pkgtools__msg_notice " \`- from    : ${address}"
}

function pypico::install()
{
    (
        pkgman setup python2
        git clone ${address} ${location}
        cd ${location}
        python setup.py --build_cython build
        python setup.py --build_cython install

        mkdir -p $(dirname ${data})
        wget -O ${data} https://owncloud.lal.in2p3.fr/index.php/s/CnrzzadQJymxHxn/download
    )
}

function pypico::uninstall()
{
    pkgtools__msg_warning "Do you really want to remove pypico ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       pip uninstall pypico
    fi
}

function pypico::setup()
{
    pkgtools__set_variable PICO_CODE ${location}
    pkgtools__set_variable PICO_DATA ${data}
}

function pypico::unsetup()
{
    pkgtools__unset_variable PICO_CODE
    pkgtools__unset_variable PICO_DATA
}
