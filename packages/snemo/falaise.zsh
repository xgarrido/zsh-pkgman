# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: falaise, supernemo
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=xgarrido
local address="git@github.com:${version}/Falaise.git"
local location="${pkgman_install_dir}/falaise/repo/${version}"
local build_dir="${location}/../../build"
local install_dir="${location}/../../install"
local local_dir=$(dirname $0)

function --falaise::select()
{
    local args=($@)
    local versions=(xgarrido SuperNEMO-DBD SuperNEMO-DBD-France)
    if [[ ${args[(r)--falaise-version=*]} ]]; then
        version=$(echo ${args[(r)--falaise-version=*]} | cut -d= -f2)
    else
        pkgtools::msg_notice "Which falaise version do you want to use ?"
        select v in ${versions[@]}; do
            version=$v
            pkgtools::msg_devel "Selecting $version"
            break
        done
    fi
    if [[ ! ${versions[(r)$version]} ]]; then
        pkgtools::msg_error "Unknown Falaise version ($version) !"
        return 1
    fi
    address="git@github.com:${version}/Falaise.git"
    location="${pkgman_install_dir}/falaise/repo/${version}"
    build_dir="${location}/../../build"
    install_dir="${location}/../../install"
    sed -i -e 's/^local version=\(.*\)/local version='${version}'/' ${local_dir}/falaise.zsh
    return 0
}

function falaise::dump()
{
    pkgtools::at_function_enter falaise::dump
    pkgtools::msg_notice "falaise"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function falaise::configure()
{
    pkgtools::at_function_enter falaise::configure
    local brew_install_dir=$(__pkgman::get_install_dir brew master)
    if [[ -z ${brew_install_dir} ]]; then
        pkgtools::msg_error "Missing brew install!"
        pkgtools::at_function_exit
        return 1
    fi
    local bayeux_install_dir=$(__pkgman::get_install_dir bayeux master)
    if [[ -z ${brew_install_dir} ]]; then
        pkgtools::msg_error "Missing bayeux install!"
        pkgtools::at_function_exit
        return 1
    fi

    # Parse Falaise options
    local falaise_options="
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_INSTALL_PREFIX=${install_dir}
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
    if $(pkgtools::has_binary ninja); then
        falaise_options+="-G Ninja -DCMAKE_MAKE_PROGRAM=$(pkgtools::get_binary_path ninja)"
    fi
    pkgtools::msg_devel "falaise_options=${falaise_options}"

    # Compiler options
    local cxx="g++"
    local cc="gcc"
    local gcc_version=$(g++ -dumpversion)
    if [[ ${gcc_version} > 7 ]]; then
        cxx+="  -Wno-noexcept-type"
    fi
    if $(pkgtools::has_binary ccache); then
        cxx="ccache ${cxx}"
        cc="ccache ${cc}"
    fi
    pkgtools::reset_variable CXX ${cxx}
    pkgtools::reset_variable CC ${cc}

    pkgtools::enter_directory ${build_dir}
    cmake $(echo ${falaise_options}) ${location}
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Configuration of falaise fails!"
        pkgtools::exit_directory
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::exit_directory
    pkgtools::at_function_exit
    return 0
}

function falaise::update()
{
    pkgtools::at_function_enter falaise::update
    if [[ ! -d ${location}/.git ]]; then
        pkgtools::msg_error "falaise is not a git repository !"
        pkgtools::at_function_exit
        return 1
    fi
    git --git-dir=${location}/.git --work-tree=${location} pull
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "falaise update fails !"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function falaise::build()
{
    pkgtools::at_function_enter falaise::build
    if $(pkgtools::has_binary ninja); then
        ninja -C ${build_dir} install
    elif $(pkgtools::has_binary make); then
        make -j$(nproc) -C ${build_dir} install
    else
        pkgtools::msg_error "Missing both 'ninja' and 'make' to compile falaise !"
        pkgtools::at_function_exit
        return 1
    fi
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Compilation of falaise fails!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function falaise::install()
{
    pkgtools::at_function_enter falaise::install
    --falaise::select $@
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Something gets wrong with Falaise version"
        pkgtools::at_function_exit
        return 1
    fi
    if [[ ! -d ${location}/.git ]]; then
        pkgtools::msg_notice "Checkout falaise from ${address}"
        git clone ${address} ${location} || \
            git clone ${address/git@github.com:/https:\/\/github.com\/} ${location}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "git clone fails!"
            pkgtools::at_function_exit
            return 1
        fi
    fi
    # Anonymous function to add falaise modules
    function {
        pkgtools::enter_directory ${location}/modules
        if [[ ! -d ParticleIdentification ]]; then
            pkgtools::msg_notice "Checkout falaise/PID module"
            git clone git@github.com:xgarrido/ParticleIdentification.git || \
                git clone https://github.com/xgarrido/ParticleIdentification.git
        fi
        if [[ ! -d ProcessReport ]]; then
            pkgtools::msg_notice "Checkout falaise/ProcessReport module"
            git clone git@github.com:xgarrido/ProcessReport.git || \
                git clone https://github.com/xgarrido/ProcessReport.git
        fi
        local gs_desc="No more FalaiseModule + PID/Process report modules"
        local gs_list=$(git stash list)
        local gs_id
        for gs in ${gs_list}; do
            if [[ $gs = *${gs_desc}* ]]; then
                gs_id=$(echo $gs | awk '{print $1}')
                break
            fi
        done
        if [[ -z ${gs_id} ]]; then
            sed -i -e 's/things2root/ParticleIdentification\nProcessReport/' CMakeLists.txt
            find . -name "CMakeLists.txt" \
                 -exec sed -i -e 's/FalaiseModule/Falaise/' {} \;
            git stash save ${gs_desc}
            git stash apply
        else
            git stash apply ${gs_id/:/}
        fi
        pkgtools::exit_directory
    }
    pkgman setup brew
    pkgman setup bayeux
    falaise::configure $@ --with-test
    falaise::build $@

    # Add emacs dir locals
    cat << EOF > ${location}/.dir-locals.el
((nil . (
         (compile-command . "ninja -C ${build_dir} install")
         )
))
EOF
    pkgtools::at_function_exit
    return 0
}

function falaise::uninstall()
{
    pkgtools::at_function_enter falaise::uninstall
    pkgtools::msg_warning "Do you really want to delete build/install directories ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf ${build_dir} ${install_dir}
    fi
    pkgtools::at_function_exit
    return 0
}

function falaise::test()
{
    pkgtools::at_function_enter falaise::test
    if $(pkgtools::has_binary ninja); then
        ninja -C ${location}/build test
    elif $(pkgtools::has_binary make); then
        make -j$(nproc) -C ${build_dir} test
    else
        pkgtools::msg_error "Missing both 'ninja' and 'make' to compile falaise !"
        pkgtools::at_function_exit
        return 1
    fi
    if $(pkgtools::last_command_fails); then
        pkgtools::msg_error "Tests of falaise fails!"
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function falaise::setup()
{
    pkgtools::at_function_enter falaise::setup
    pkgtools::msg_notice "Using falaise/${version}"
    pkgtools::add_path_to_PATH ${install_dir}/bin
    pkgtools::at_function_exit
    return 0
}

function falaise::unsetup()
{
    pkgtools::at_function_enter falaise::unsetup
    pkgtools::remove_path_to_PATH ${install_dir}/bin
    pkgtools::at_function_exit
    return 0
}
