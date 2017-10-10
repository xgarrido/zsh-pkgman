# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: python, 2.7, virtualenv
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=2.7
local location="${pkgman_install_dir}/python.d/cmb_${version}"

function python2::dump()
{
    pkgtools__msg_notice "Python"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- to      : ${location}"
}

function python2::install()
{
    if [ ! -d ${location} ]; then
        virtualenv --python=/usr/bin/python2.7 ${location}
    fi
    python2::setup
    pip install -U pip numpy==1.6.1 scipy==0.10.1 cython pyfits ipython jupyter
    python2::unsetup
}

function python2::uninstall()
{
    pkgtools__msg_warning "Do you really want to delete ${location} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}
    fi
}

function python2::setup()
{
    source ${location}/bin/activate
}

function python2::unsetup()
{
    if [[ ${location} = $VIRTUAL_ENV ]]; then
        deactivate
    fi
}
