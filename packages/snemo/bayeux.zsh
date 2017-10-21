# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: bayeux, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local address="git@github.com:BxCppDev/Bayeux.git"
local location="${pkgman_install_dir}/bayeux"

function bayeux::dump()
{
    __pkgtools__at_function_enter bayeux::dump
    pkgtools__msg_notice "bayeux"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- from    : ${address}"
    pkgtools__msg_notice " \`- to      : ${location}"
    __pkgtools__at_function_exit
    return 0
}

function bayeux::configure()
{
    __pkgtools__at_function_enter bayeux::configure

    local brew_install_dir=$(__pkgman::get_install_dir brew master)
    if [[ -z ${brew_install_dir} ]]; then
        pkgtools__msg_error "Missing brew install!"
        __pkgtools__at_function_exit
        return 1
    fi

    # Parse Bayeux options
    local bayeux_options="
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INSTALL_PREFIX=${location}/install
        -DCMAKE_PREFIX_PATH=${brew_install_dir}/brew
        -DBAYEUX_CXX_STANDARD=14
        -DBAYEUX_WITH_QT_GUI=ON "
    local args=($@)
    local -A opts=(with-test       BAYEUX_ENABLE_TESTING
                   with-doc        BAYEUX_WITH_DOCS
                   without-warning BAYEUX_COMPILER_ERROR_ON_WARNING)
    for k in "${(@k)opts}"; do
        if [[ ${args[(r)--$k]} == --$k ]]; then
            bayeux_options+="-D${opts[$k]}="
            [[ $k == without-* ]] && bayeux_options+="OFF " || bayeux_options+="ON "
        else
            # elif [[ ${args[(r)--without-$k]} == --without-$k ]]; then
            bayeux_options+="-D${opts[$k]}="
            [[ $k == without-* ]] && bayeux_options+="ON " || bayeux_options+="OFF "
        fi
    done
    if $(pkgtools__has_binary ninja); then
        bayeux_options+="-G Ninja -DCMAKE_MAKE_PROGRAM=$(pkgtools__get_binary_path ninja)"
    fi
    pkgtools__msg_devel "bayeux_options=${bayeux_options}"

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
    cmake $(echo ${bayeux_options}) ${location}/${version}
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Configuration of bayeux fails!"
        ret=1
    fi
    pkgtools__exit_directory
    __pkgtools__at_function_exit
    return ${ret}
}

function bayeux::build()
{
    __pkgtools__at_function_enter bayeux::build
    if $(pkgtools__has_binary ninja); then
        ninja -C ${location}/build install
    elif $(pkgtools__has_binary make); then
        make -j$(nproc) -C ${location}/build install
    else
        pkgtools__msg_error "Missing both 'ninja' and 'make' to compile bayeux !"
        __pkgtools__at_function_exit
        return 1
    fi
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Compilation of bayeux fails!"
        __pkgtools__at_function_exit
        return 1
    fi
    __pkgtools__at_function_exit
    return 0
}

function bayeux::install()
{
    __pkgtools__at_function_enter bayeux::install
    if [[ ! -d ${location}/${version}/.git ]]; then
        pkgtools__msg_notice "Checkout bayeux from ${address}"
        git clone ${address} ${location}/${version}
    fi
    bayeux::configure $@ --with-test
    bayeux::build $@

    # Add emacs dir locals
    cat << EOF > ${location}/${version}/.dir-locals.el
((nil . (
         (compile-command . "ninja -C ${location}/build install")
         )
))
EOF
    __pkgtools__at_function_exit
    return 0
}

function bayeux::uninstall()
{
    __pkgtools__at_function_enter bayeux::uninstall
    pkgtools__msg_warning "Do you really want to delete ${location}/{build,install} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}/{build,install}
    fi
    __pkgtools__at_function_exit
    return 0
}

function bayeux::test()
{
    __pkgtools__at_function_enter bayeux::test
    if $(pkgtools__has_binary ninja); then
        ninja -C ${location}/build test
    elif $(pkgtools__has_binary make); then
        make -j$(nproc) -C ${location}/build test
    else
        pkgtools__msg_error "Missing both 'ninja' and 'make' to compile bayeux !"
        __pkgtools__at_function_exit
        return 1
    fi
    if $(pkgtools__last_command_fails); then
        pkgtools__msg_error "Tests of bayeux fails!"
        __pkgtools__at_function_exit
        return 1
    fi
    __pkgtools__at_function_exit
    return 0
}

function bayeux::setup()
{
    __pkgtools__at_function_enter bayeux::setup
    pkgtools__add_path_to_PATH ${location}/install/bin
    __pkgtools__at_function_exit
    return 0
}

function bayeux::unsetup()
{
    __pkgtools__at_function_enter bayeux::unsetup
    pkgtools__remove_path_to_PATH ${location}/install/bin
    __pkgtools__at_function_exit
    return 0
}
