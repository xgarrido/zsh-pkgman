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
        local pips=(pip numpy==1.12.1 scipy matplotlib ipython jupyter cython pyfits healpy pymc \
                        git+https://github.com/bthorne93/PySM_public.git)
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

function python2::test()
{
    pkgtools::at_function_enter python2::test
    (
        python2::setup
        cd $(mktemp -d)
        pkgtools::msg_notice "Testing python2 installation..."
        pkgtools::msg_notice "Testing matplotlib installation..."
        {
            echo "import matplotlib.pyplot as plt"
        } >> test_python2.py
        python test_python2.py
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Test of python2 library fails!"
            pkgtools::at_function_exit
            return 1
        fi
        rm -rf $(pwd)
        pkgtools::msg_notice "All tests passed!"
    )
    pkgtools::at_function_exit
    return 0
}

function python2::setup()
{
    pkgtools::at_function_enter python2::setup
    pkgtools::msg_notice -n "Configuring python2..."
    source ${location}/bin/activate
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_color_red; echo "\033[3D ➜ error"; pkgtools::msg_color_normal
        pkgtools::msg_error "Something wrong occurs when initializing python2!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::at_function_exit
    return 0
}

function python2::unsetup()
{
    pkgtools::at_function_enter python2::unsetup
    pkgtools::msg_notice -n "Unconfiguring python2..."
    if [[ ${location} = $VIRTUAL_ENV ]]; then
        deactivate
    fi
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::at_function_exit
    return 0
}
