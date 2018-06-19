# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: SNFrontEntElectronics
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="git@gitlab.in2p3.fr:SuperNEMO-DBD/SNFrontEndElectronics.git"
local location="${pkgman_install_dir}/snfee"

function snfee::dump()
{
    pkgtools::at_function_enter snfee::dump
    pkgtools::msg_notice "snfee"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " \`- from    : ${address}"
    pkgtools::at_function_exit
    return 0
}

function snfee::configure()
{
    pkgtools::at_function_enter snfee::configure

    local bayeux_install_dir=$(__pkgman::get_install_dir bayeux master)
    if [[ -z ${bayeux_install_dir} ]]; then
        pkgtools::msg_error "Missing bayeux install!"
        pkgtools::at_function_exit
        return 1
    fi

    # Parse snfee options
    local snfee_options="
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INSTALL_PREFIX=${location}/install
        -DCMAKE_PREFIX_PATH=${bayeux_install_dir}/install "
    if $(pkgtools::has_binary ninja); then
        snfee_options+="-G Ninja -DCMAKE_MAKE_PROGRAM=$(pkgtools::get_binary_path ninja)"
    fi
    pkgtools::msg_devel "snfee_options = ${snfee_options}"

    # Compiler options
    local cxx="g++"
    local cc="gcc"
    local gcc_version=$(g++ -dumpversion)
    if [[ ${gcc_version} > 7 ]]; then
        cxx+=" -Wno-noexcept-type"
    fi
    if $(pkgtools::has_binary ccache); then
        cxx="ccache ${cxx}"
        cc="ccache ${cc}"
    fi

    pkgtools::reset_variable CXX ${cxx}
    pkgtools::reset_variable CC ${cc}

    pkgtools::enter_directory ${location}/build
    cmake $(echo ${snfee_options}) ${location}/${version}
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Configuration of snfee fails!"
        pkgtools::exit_directory
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::exit_directory
    pkgtools::at_function_exit
    return 0
}

function snfee::update()
{
    pkgtools::at_function_enter snfee::update
    if [[ ! -d ${location}/${version}/.git ]]; then
        pkgtools::msg_error "snfee is not a git repository !"
        pkgtools::at_function_exit
        return 1
    fi
    git --git-dir=${location}/${version}/.git --work-tree=${location}/${version} pull
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "snfee update fails !"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function snfee::build()
{
    pkgtools::at_function_enter snfee::build
    if $(pkgtools::has_binary ninja); then
        LC_ALL=C ninja -C ${location}/build install
    elif $(pkgtools::has_binary make); then
        LC_ALL=C make -j$(nproc) -C ${location}/build install
    else
        pkgtools::msg_error "Missing both 'ninja' and 'make' to compile bayeux !"
        pkgtools::at_function_exit
        return 1
    fi
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Compilation of snfee fails!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function snfee::install()
{
    pkgtools::at_function_enter snfee::install
    if [[ ! -d ${location}/${version}/.git ]]; then
        pkgtools::msg_notice "Checkout snfee from ${address}"
        git clone ${address} ${location}/${version}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "git clone fails!"
            pkgtools::at_function_exit
            return 1
        fi
    fi
    pkgman $@ setup bayeux
    snfee::configure $@ --with-test
    snfee::build $@

    # Add emacs dir locals
    cat << EOF > ${location}/${version}/.dir-locals.el
((nil . (
         (compile-command . "ninja -C ${location}/build install")
         )
))
EOF

    pkgtools::at_function_exit
    return 0
}

function snfee::uninstall()
{
    pkgtools::at_function_enter snfee::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location}/{build,install} ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf ${location}/{build,install}
    fi
    pkgtools::at_function_exit
    return 0
}

function snfee::test()
{
    pkgtools::at_function_enter snfee::test
    if $(pkgtools::has_binary ninja); then
        ninja -C ${location}/build test
    elif $(pkgtools::has_binary make); then
        make -j$(nproc) -C ${location}/build test
    else
        pkgtools::msg_error "Missing both 'ninja' and 'make' to compile bayeux !"
        pkgtools::at_function_exit
        return 1
    fi
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Tests of snfee fails!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function snfee::setup()
{
    pkgtools::at_function_enter snfee::setup
    pkgtools::at_function_exit
    return 0
}

function snfee::unsetup()
{
    pkgtools::at_function_enter snfee::unsetup
    pkgtools::at_function_exit
    return 0
}
