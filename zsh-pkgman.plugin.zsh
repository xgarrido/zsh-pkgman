# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: package manager
# Requirements: pkgtools
# Status: not intended to be distributed yet

local pkgman_dir=$(dirname $0)

function pkgman()
{
    __pkgtools__default_values
    __pkgtools__at_function_enter pkgman

    local fcns=(setup unsetup update install uninstall dump)

    local mode
    local append_list_of_pkgs_arg
    local append_list_of_options_arg
    local pkgman_install_dir=/tmp
    while [ -n "$1" ]; do
        local token="$1"
        if [ "${token[0,1]}" = "-" ]; then
	    local opt=${token}
            append_list_of_options_arg+="${opt} "
	    if [[ ${opt} = -h || ${opt} = --help ]]; then
                return 0
	    elif [[ ${opt} = -d || ${opt} = --debug ]]; then
	        pkgtools__msg_using_debug
	    elif [[ ${opt} = -D || ${opt} = --devel ]]; then
	        pkgtools__msg_using_devel
	    elif [[ ${opt} = -v || ${opt} = --verbose ]]; then
	        pkgtools__msg_using_verbose
	    elif [[ ${opt} = -W || ${opt} = --no-warning ]]; then
	        pkgtools__msg_not_using_warning
	    elif [[ ${opt} = -q || ${opt} = --quiet ]]; then
	        pkgtools__msg_using_quiet
	    elif [[ ${opt} = --install-dir ]]; then
                shift 1
                pkgman_install_dir="$1"
            fi
        else
            if (( ${fcns[(I)${token}]} )); then
                pkgtools__msg_devel "Mode ${token} exists !"
                mode=${token}
            else
                pkgtools__msg_devel "Mode ${token} does not exist !"
	        append_list_of_pkgs_arg+="${token} "
            fi
        fi
        shift 1
    done
    # Remove last space
    append_list_of_pkgs_arg=${append_list_of_pkgs_arg%?}
    append_list_of_options_arg=${append_list_of_options_arg%?}

    pkgtools__msg_devel "mode=${mode}"
    pkgtools__msg_devel "append_list_of_pkgs_arg=${append_list_of_pkgs_arg}"
    pkgtools__msg_devel "append_list_of_options_arg=${append_list_of_options_arg}"

    # Make sure about the install location
    # pkgtools__msg_warning \
    #     "Do you want to install software within '${pkgman_install_dir}' directory ?"
    # pkgtools__yesno_question
    # if $(pkgtools__answer_is_no); then
    #     __pkgtools__at_function_exit
    #     return 1
    # fi

    local -a loaded_pkgs
    function --load_pkgs()
    {
        loaded_pkgs+=($1)
    }

    local packages_dir=${pkgman_dir}/packages
    for ipkg in ${=append_list_of_pkgs_arg}; do
        pkgtools__msg_debug "Check existence of package '${ipkg}'"
        local pkg=$(basename $ipkg)
        local pkg_file=$(find ${packages_dir}/$(dirname $ipkg) -name ${pkg}.zsh)
        pkgtools__msg_devel "pkg_file=${pkg_file}"
        if [[ -z ${pkg_file} ]]; then
	    pkgtools__msg_error "Package '${ipkg}' not found !"
            continue
        elif [[ $(echo "${pkg_file}" | wc -l) > 1 ]]; then
            pkgtools__msg_error "Package '${ipkg}' has ambiguous declaration !"
            pkgtools__msg_error "Choose between "$(echo "${pkg_file}" | sed -e 's#'${packages_dir}'/./##g' -e 's/.zsh$//')
            continue
	fi

        pkgtools__msg_debug "Load '${pkg_file}' file..."
        . ${pkg_file} && --load_pkgs ${pkg}
        local fcn="${pkg}::${mode}"
        if (( ! $+functions[$fcn] )); then
            pkgtools__msg_error "Missing function '$fcn' ! Need to be implemented within '${pkg_file}'!"
        else
            pkgtools__msg_debug "Run '$fcn' function"
            $fcn
        fi
    done

    for ipkg in ${loaded_pkgs}; do
        for ifcn in ${fcns}; do
            local fcn="${ipkg}::${ifcn}"
            if (( $+functions[$fcn] )); then
                pkgtools__msg_devel "Unloading $fcn function"
                unfunction $fcn
            fi
        done
    done

    __pkgtools__at_function_exit
    return 0
}
