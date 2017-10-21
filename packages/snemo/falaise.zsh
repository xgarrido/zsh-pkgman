# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: falaise, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="git@github.com:SuperNEMO-DBD-France/Falaise.git"
local location="${pkgman_install_dir}/falaise"

function falaise::dump()
{
    __pkgtools__at_function_enter falaise::dump
    pkgtools__msg_notice "falaise"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- from    : ${address}"
    pkgtools__msg_notice " \`- to      : ${location}"
    __pkgtools__at_function_exit
    return 0
}

function falaise::configure()
{
    __pkgtools__at_function_enter falaise::configure

    local brew_install_dir=$(__pkgman::get_install_dir brew master)
    if [[ -z ${brew_install_dir} ]]; then
        pkgtools__msg_error "Missing brew install!"
        __pkgtools__at_function_exit
        return 1
    fi
    local bayeux_install_dir=$(__pkgman::get_install_dir bayeux master)
    if [[ -z ${brew_install_dir} ]]; then
        pkgtools__msg_error "Missing bayeux install!"
        __pkgtools__at_function_exit
        return 1
    fi

    # Parse Falaise options
    local falaise_options="
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INSTALL_PREFIX=${location}/install
        -DCMAKE_PREFIX_PATH=${brew_install_dir}/brew;${bayeux_install_dir}/bayeux/install
        -DFALAISE_WITH_DEVELOPER_TOOLS=ON
        -DFALAISE_CXX_STANDARD=14 "
    local args=($@)
    local -A opts=(with-test       FALAISE_ENABLE_TESTING
                   with-doc        FALAISE_WITH_DOCS
                   without-warning FALAISE_COMPILER_ERROR_ON_WARNING)
    for k in "${(@k)opts}"; do
        if [[ ${args[(r)--$k]} == --$k ]]; then
            falaise_options+="-D${opts[$k]}="
            [[ $k == without-* ]] && falaise_options+="OFF " || falaise_options+="ON "
        else
            # elif [[ ${args[(r)--without-$k]} == --without-$k ]]; then
            falaise_options+="-D${opts[$k]}="
            [[ $k == without-* ]] && falaise_options+="ON " || falaise_options+="OFF "
        fi
    done
    if $(pkgtools__has_binary ninja); then
        falaise_options+="-G Ninja -DCMAKE_MAKE_PROGRAM=$(pkgtools__get_binary_path ninja)"
    fi
    pkgtools__msg_devel "falaise_options=${falaise_options}"

    # Compiler options
    local cxx="g++ -Wno-noexcept-type"
    local cc="gcc"
    if $(pkgtools__has_binary ccache); then
        cxx="ccache ${cxx}"
        cc="ccache ${cc}"
    fi
    pkgtools__reset_variable CXX ${cxx}
    pkgtools__reset_variable CC ${cc}

    local ret=0
    pkgtools__enter_directory ${location}/build
    cmake $(echo ${falaise_options}) ${location}/${version}
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Configuration of falaise fails!"
        ret=1
    fi
    pkgtools__exit_directory
    __pkgtools__at_function_exit
    return ${ret}
}

function falaise::build()
{
    __pkgtools__at_function_enter falaise::build
    if $(pkgtools__has_binary ninja); then
        ninja -C ${location}/build install
    elif $(pkgtools__has_binary make); then
        make -j$(nproc) -C ${location}/build install
    else
        pkgtools__msg_error "Missing both 'ninja' and 'make' to compile falaise !"
        __pkgtools__at_function_exit
        return 1
    fi
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Compilation of falaise fails!"
        __pkgtools__at_function_exit
        return 1
    fi
    __pkgtools__at_function_exit
    return 0
}

function falaise::install()
{
    __pkgtools__at_function_enter falaise::install
    if [[ ! -d ${location}/${version}/.git ]]; then
        pkgtools__msg_notice "Checkout falaise from ${address}"
        git clone ${address} ${location}/${version}
    fi
    falaise::configure $@ --with-test
    falaise::build $@
    __pkgtools__at_function_exit
    return 0
}

function falaise::uninstall()
{
    __pkgtools__at_function_enter falaise::uninstall
    pkgtools__msg_warning "Do you really want to delete ${location}/{build,install} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}/{build,install}
    fi
    __pkgtools__at_function_exit
    return 0
}

function falaise::test()
{
    __pkgtools__at_function_enter falaise::test
    if $(pkgtools__has_binary ninja); then
        ninja -C ${location}/build test
    elif $(pkgtools__has_binary make); then
        make -j$(nproc) -C ${location}/build test
    else
        pkgtools__msg_error "Missing both 'ninja' and 'make' to compile falaise !"
        __pkgtools__at_function_exit
        return 1
    fi
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Tests of falaise fails!"
        __pkgtools__at_function_exit
        return 1
    fi
    __pkgtools__at_function_exit
    return 0
}

function falaise::setup()
{
    __pkgtools__at_function_enter falaise::setup
    pkgtools__add_path_to_PATH ${location}/install/bin
    __pkgtools__at_function_exit
    return 0
}

function falaise::unsetup()
{
    __pkgtools__at_function_enter falaise::unsetup
    pkgtools__remove_path_to_PATH ${location}/install/bin
    __pkgtools__at_function_exit
    return 0
}
