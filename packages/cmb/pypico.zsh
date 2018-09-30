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

        local args=($@)
        if [[ ! ${args[(r)--without-data]} && ! -d ${data} ]]; then
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

function pypico::test()
{
    pkgtools::at_function_enter pypico::test
    (
        pypico::setup
        cd $(mktemp -d)
        pkgtools::msg_notice "Testing pypico..."
        pkgman setup python2
        {
            echo "import pypico"
            echo "import os"
            echo "print(pypico.get_include())"
            echo "print(pypico.get_link())"
            echo "pico = pypico.load_pico(os.path.expandvars(\"$PICO_DATA\"))"
            echo "result = pico.get(**pico.example_inputs())"
            echo "print(result)"
        } >> test_pico.py
        python test_pico.py
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Test of pypico library fails!"
            pkgtools::at_function_exit
            return 1
        fi
        rm -rf $(pwd)
        pkgtools::msg_notice "All tests passed!"
    )
    pkgtools::at_function_exit
    return 0
}

function pypico::setup()
{
    pkgtools::at_function_enter pypico::setup
    pkgtools::msg_notice -n "Configuring pypico..."
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::set_variable PICO_CODE ${location}
    pkgtools::set_variable PICO_DATA ${data}
    pkgtools::at_function_exit
    return 0
}

function pypico::unsetup()
{
    pkgtools::at_function_enter pypico::unsetup
    pkgtools::msg_notice -n "Unconfiguring pypico..."
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::unset_variable PICO_CODE
    pkgtools::unset_variable PICO_DATA
    pkgtools::at_function_exit
    return 0
}
