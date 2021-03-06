# -*- mode: shell-script; -*-
#
# Copyright (C) 2017-2019 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: bayeux, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=BxCppDev
local address="git@github.com:xgarrido/Bayeux.git"
local location="${pkgman_install_dir}/bayeux/repo/${version}"
local build_dir="${pkgman_install_dir}/bayeux/build"
local install_dir="${pkgman_install_dir}/bayeux/install"
local local_dir=$(dirname $0)

function --bayeux::select()
{
    local args=($@)
    local versions=(xgarrido BxCppDev)
    if [[ ${args[(r)--bayeux-version=*]} ]]; then
        version=$(echo ${args[(r)--bayeux-version=*]} | cut -d= -f2)
    else
        pkgtools::msg_notice "Which Bayeux version do you want to use ?"
        select v in ${versions[@]}; do
            version=$v
            pkgtools::msg_devel "Selecting $version"
            break
        done
    fi
    if [[ ! ${versions[(r)$version]} ]]; then
        pkgtools::msg_error "Unknown Bayeux version ($version) !"
        return 1
    fi
    address="git@github.com:${version}/Bayeux.git"
    location="${pkgman_install_dir}/bayeux/repo/${version}"
    build_dir="${location}/../../build"
    install_dir="${location}/../../install"
    sed -i -e 's/^local version=\(.*\)/local version='${version}'/' ${local_dir}/bayeux.zsh
    return 0
}

function bayeux::dump()
{
    pkgtools::at_function_enter bayeux::dump
    pkgtools::msg_notice "bayeux"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function bayeux::configure()
{
    pkgtools::at_function_enter bayeux::configure

    local brew_install_dir=$(__pkgman::get_install_dir brew master)
    if [[ -z ${brew_install_dir} ]]; then
        pkgtools::msg_error "Missing brew install!"
        pkgtools::at_function_exit
        return 1
    fi

    # Parse Bayeux options
    local bayeux_options="
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INSTALL_PREFIX=${install_dir}
        -DCMAKE_PREFIX_PATH=${brew_install_dir}/brew
        -DBAYEUX_CXX_STANDARD=14 "
    if [[ $(hostname) != cca* ]]; then
        bayeux_options+="-DBAYEUX_WITH_QT_GUI=ON "
    fi
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
    if $(pkgtools::has_binary ninja); then
        bayeux_options+="-G Ninja -DCMAKE_MAKE_PROGRAM=$(pkgtools::get_binary_path ninja)"
    fi
    pkgtools::msg_devel "bayeux_options=${bayeux_options}"

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

    pkgtools::enter_directory ${build_dir}
    cmake $(echo ${bayeux_options}) ${location}
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Configuration of bayeux fails!"
        pkgtools::exit_directory
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::exit_directory
    pkgtools::at_function_exit
    return 0
}

function bayeux::update()
{
    pkgtools::at_function_enter bayeux::update
    if [[ ! -d ${location}/.git ]]; then
        pkgtools::msg_error "bayeux is not a git repository !"
        pkgtools::at_function_exit
        return 1
    fi
    git --git-dir=${location}/.git --work-tree=${location} pull
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "bayeux update fails !"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function bayeux::build()
{
    pkgtools::at_function_enter bayeux::build
    if $(pkgtools::has_binary ninja); then
        LC_ALL=C ninja -C ${build_dir} install
    elif $(pkgtools::has_binary make); then
        LC_ALL=C make -j$(nproc) -C ${build_dir} install
    else
        pkgtools::msg_error "Missing both 'ninja' and 'make' to compile bayeux !"
        pkgtools::at_function_exit
        return 1
    fi
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Compilation of bayeux fails!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function bayeux::install()
{
    pkgtools::at_function_enter bayeux::install
    --bayeux::select $@
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Something gets wrong with Bayeux version"
        pkgtools::at_function_exit
        return 1
    fi
    if [[ ! -d ${location}/.git ]]; then
        pkgtools::msg_notice "Checkout bayeux from ${address}"
        git clone ${address} ${location} || \
            git clone ${address/git@github.com:/https:\/\/github.com\/} ${location}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "git clone fails!"
            pkgtools::at_function_exit
            return 1
        fi
    fi
    pkgman $@ setup brew
    bayeux::configure $@ --with-test
    bayeux::build $@

    # Add emacs dir locals
    cat << EOF > ${location}/.dir-locals.el
((nil . (
         (compile-command . "ninja -C ${location}/build install")
         )
))
EOF
    pkgtools::at_function_exit
    return 0
}

function bayeux::uninstall()
{
    pkgtools::at_function_enter bayeux::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location}/{build,install} ?"
    pkgtools::yesno_question "Answer ? "
    if $(pkgtools::answer_is_yes); then
        rm -rf ${build_dir} ${install_dir}
    fi
    pkgtools::at_function_exit
    return 0
}

function bayeux::test()
{
    pkgtools::at_function_enter bayeux::test
    if $(pkgtools::has_binary ninja); then
        ninja -C ${build_dir} test
    elif $(pkgtools::has_binary make); then
        make -j$(nproc) -C ${build_dir} test
    else
        pkgtools::msg_error "Missing both 'ninja' and 'make' to compile bayeux !"
        pkgtools::at_function_exit
        return 1
    fi
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Tests of bayeux fails!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function bayeux::setup()
{
    pkgtools::at_function_enter bayeux::setup
    pkgtools::add_path_to_PATH ${install_dir}/bin
    pkgtools::at_function_exit
    return 0
}

function bayeux::unsetup()
{
    pkgtools::at_function_enter bayeux::unsetup
    pkgtools::remove_path_to_PATH ${install_dir}/bin
    pkgtools::at_function_exit
    return 0
}
