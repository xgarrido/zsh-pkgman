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
    pkgtools__msg_notice " \`- to      : ${location}"
}

function python2::install()
{
    if [ ! -d ${location} ]; then
        if ! $(pkgtools__has_binary virtualenv); then
            (
                cd $(mktemp -d)
                wget \
                    "https://pypi.python.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz#md5=44e19f4134906fe2d75124427dc9b716"
                tar xzvf virtualenv-15.1.0.tar.gz
                cd virtualenv-15.1.0
                python${version} virtualenv.py ${location}
                rm -rf $(pwd)
            )
        else
            virtualenv --python=$(which python)/${version} ${location}
        fi
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
