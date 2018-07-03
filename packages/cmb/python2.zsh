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
    pkgtools::at_function_enter python2::dump
    pkgtools::msg_notice "Python"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " |- pip packages:"
    (
        python2::setup
        for p in $(pip freeze); do
            pkgtools::msg_notice "    |-" $(echo $p | sed 's/==/ -> /g')
        done
    )
    pkgtools::at_function_exit
    return 0
}

function python2::install()
{
    pkgtools::at_function_enter python2::install
    (
        if [ ! -d ${location} ]; then
            if ! $(pkgtools::has_binary virtualenv); then
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
                virtualenv --python=$(which python)${version} ${location}
            fi
        fi
        python2::setup
        local pips=(pip numpy==1.12.1 scipy matplotlib ipython jupyter cython pyfits healpy pymc)
        for i in ${pips}; do
            pip --cache-dir /tmp/pip.d install $i
            if $(pkgtools::last_command_fails); then
                pkgtools::msg_error "Something wrong occurs when installing $i python packages!"
                pkgtools::at_function_exit
                return 1
            fi
        done
    )
    pkgtools::at_function_exit
    return 0
}

function python2::uninstall()
{
    pkgtools::at_function_enter python2::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location} ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function python2::setup()
{
    pkgtools::at_function_enter python2::setup
    source ${location}/bin/activate
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Something wrong occurs when initializing python2!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function python2::unsetup()
{
    pkgtools::at_function_enter python2::unsetup
    if [[ ${location} = $VIRTUAL_ENV ]]; then
        deactivate
    fi
    pkgtools::at_function_exit
    return 0
}
