# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: package manager
# Requirements: pkgtools
# Status: not intended to be distributed yet

# Add completion
fpath=(${ADOTDIR}/bundles/xgarrido/zsh-pkgman/completions $fpath)

pkgman_dir=$(dirname $0)
pkgman_install_dir=/tmp/
export PKGMAN_SETUP_DONE

function pkgman()
{
    pkgtools::default_values
    pkgtools::at_function_enter pkgman

    local packages_dir=${pkgman_dir}/packages

    local fcns=(setup unsetup configure build install uninstall
                dump goto update test)

    local mode
    local append_list_of_pkgs_arg
    local append_list_of_options_arg
    local new_pkgman_install_dir

    while [ -n "$1" ]; do
        local token="$1"
        if [ ${token[0,1]} = - ]; then
	    local opt=${token}
	    if [[ ${opt} = -h || ${opt} = --help ]]; then
                return 0
	    elif [[ ${opt} = -d || ${opt} = --debug ]]; then
	        pkgtools::msg_using_debug
                append_list_of_options_arg+="${opt} "
	    elif [[ ${opt} = -D || ${opt} = --devel ]]; then
	        pkgtools::msg_using_devel
                append_list_of_options_arg+="${opt} "
	    elif [[ ${opt} = -v || ${opt} = --verbose ]]; then
	        pkgtools::msg_using_verbose
                append_list_of_options_arg+="${opt} "
	    elif [[ ${opt} = -q || ${opt} = --quiet ]]; then
	        pkgtools::msg_using_quiet
	    elif [[ ${opt} = -W || ${opt} = --no-warning ]]; then
	        pkgtools::msg_not_using_warning
	    elif [[ ${opt} = --install-dir ]]; then
                shift 1
                new_pkgman_install_dir="$1"
            else
                append_list_of_options_arg+="${opt} "
            fi
        else
            if (( ${fcns[(I)${token}]} )); then
                pkgtools::msg_devel "Mode ${token} exists !"
                mode=${token}
            elif [[ ${token} = add ]]; then
                shift 1
                local address="$1"
                pkgtools::msg_notice "Adding packages from ${address}"
                git clone git@github.com:$address ${packages_dir}/${address}
            else
                pkgtools::msg_devel "Adding package ${token} !"
	        append_list_of_pkgs_arg+="${token} "
            fi
        fi
        shift 1
    done
    # Remove last space
    append_list_of_pkgs_arg=${append_list_of_pkgs_arg%?}
    append_list_of_options_arg=${append_list_of_options_arg%?}

    pkgtools::msg_devel "mode=${mode}"
    pkgtools::msg_devel "append_list_of_pkgs_arg=${append_list_of_pkgs_arg}"
    pkgtools::msg_devel "append_list_of_options_arg=${append_list_of_options_arg}"

    # pkgman internal database
    local pkgman_db_file=${pkgman_dir}/.pkgman_db_file
    [[ ! -f ${pkgman_db_file} ]] && touch ${pkgman_db_file}

    # Internal functions
    __pkgman::get_install_dir()
    {
        local pkg=$1
        local version=$2
        local install_dir="$(cat $pkgman_db_file | awk '/^'${pkg}'.*'${version}'/{print $3}')"
        echo ${install_dir}
    }

    __pkgman::store_install_dir()
    {
        local pkg=$1
        local version=$2
        local new_install_dir=$3
        local current_install_dir=$(__pkgman::get_install_dir $pkg $version)
        if [[ ${current_install_dir} = ${new_install_dir} ]]; then
            __pkgman::remove_install_dir $(echo ${pkg} ${version})
        fi
        echo ${ipkg} ${version} ${new_install_dir} >> ${pkgman_db_file}
    }

    __pkgman::remove_install_dir()
    {
        local pkg=$1
        local version=$2
        sed -i -e '/^'${pkg}'.*'${version}'/d' ${pkgman_db_file}
    }

    local -a loaded_pkgs
    for ipkg in ${=append_list_of_pkgs_arg}; do
        pkgtools::msg_debug "Check existence of package '${ipkg}'"
        local pkg=$(basename $ipkg)
        local pkg_file=$(find ${packages_dir}/$(dirname $ipkg) -name ${pkg}.zsh)
        pkgtools::msg_devel "pkg_file=${pkg_file}"
        if [[ -z ${pkg_file} ]]; then
	    pkgtools::msg_error "Package '${ipkg}' not found !"
            continue
        elif [[ $(echo "${pkg_file}" | wc -l) > 1 ]]; then
            pkgtools::msg_error "Package '${ipkg}' has ambiguous declaration!"
            pkgtools::msg_error "Choose between "$(echo "${pkg_file}" | sed -e 's#'${packages_dir}'/./##g' -e 's/.zsh$//')
            continue
	fi

        pkgtools::msg_debug "Load '${pkg}' package..."
        . ${pkg_file} && loaded_pkgs+=(${pkg})
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Package '${pkg}' can not be run!"
            continue
        fi

        # Check for aggregator of packages
        local has_decorator=false
        if [[ ${pkg} = @* ]]; then
            has_decorator=true
            pkg=${pkg:1}
        fi
        pkgtools::msg_devel "has_decorator = ${has_decorator}"

        # Check package version
        if [[ -z ${version} && ${has_decorator} = false ]]; then
            pkgtools::msg_error "Missing package version!"
            continue
        fi

        pkgtools::msg_devel "Looking for ${ipkg} package (version ${version})"

        # Install directory from database
        local pkg_install_dir=$(__pkgman::get_install_dir ${ipkg} ${version})
        if [[ -z ${pkg_install_dir} ]]; then
            if [[ ${has_decorator} = false && ${mode} != install ]]; then
                pkgtools::msg_error "The current package ${ipkg} is not installed!"
                continue
            fi
        else
            if [[ ${mode} = install ]]; then
                pkgtools::msg_warning \
                    "The current package ${ipkg} is already installed @ ${pkg_install_dir}! Remove it first!"
                continue
            fi
            pkgman_install_dir=${pkg_install_dir}
        fi
        # If install dir is not empty, it means it has been forced
        if [[ -n ${new_pkgman_install_dir} ]]; then
            pkgman_install_dir=${new_pkgman_install_dir}
        fi
        pkgtools::msg_devel "pkgman_install_dir = ${pkgman_install_dir}"
        # Need to be reloaded to update location variable
        if ! ${has_decorator}; then
            . ${pkg_file}
        fi

        # Goto mode
        if [[ ${mode} = goto ]]; then
            if ${has_decorator}; then
                pkgtools::msg_error "Can not go into a decorator package!"
                pkgtools::at_function_exit
                return 1
            else
                cd ${location}
                break
            fi
        fi

        local fcn="${pkg}::${mode}"
        if (( ! $+functions[$fcn] )); then
            pkgtools::msg_error \
                "Missing function '$fcn'! Need to be implemented within '${pkg_file}'!"
        else
            pkgtools::msg_debug "Run '$fcn' function for version ${version}"
            $fcn ${append_list_of_options_arg}
            if $(pkgtools::last_command_succeeds); then
                pkgtools::msg_devel "Function '$fcn' successfully finished"
                if ! ${has_decorator}; then
                    if [[ ! -z ${version} ]]; then
                        # Update info and get latest package to get installed
                        . ${pkg_file} && ipkg=${loaded_pkgs[@]}
                        if [[ ${mode} = install ]]; then
                            pkgtools::msg_devel "Store install directory ${pkgman_install_dir} for ${ipkg} and version ${version}"
                            __pkgman::store_install_dir $(echo ${ipkg} ${version} ${pkgman_install_dir})
                        elif [[ ${mode} = uninstall ]]; then
                            __pkgman::remove_install_dir $(echo ${ipkg} ${version})
                        fi
                    fi
                fi
            else
                pkgtools::msg_error "Running '$fcn' function fails !"
            fi
        fi
    done

    for ipkg in ${loaded_pkgs}; do
        for ifcn in ${fcns}; do
            local fcn="${ipkg}::${ifcn}"
            if (( $+functions[$fcn] )); then
                pkgtools::msg_devel "Unloading $fcn function"
                unfunction $fcn
            fi
        done
    done

    # local internals_fcns=(__pkgman::get_install_dir
    #                       __pkgman::store_install_dir
    #                       __pkgman::remove_install_dir)
    # for ifcn in ${internals_fcns}; do
    #     if (( $+functions[$ifcn] )); then
    #         pkgtools::msg_devel "Unloading $ifcn function"
    #         unfunction $ifcn
    #     fi
    # done

    # Remove duplicate lines
    awk '!seen[$0]++' ${pkgman_db_file} > ${pkgman_db_file}.tmp
    mv ${pkgman_db_file}.tmp ${pkgman_db_file}

    pkgtools::at_function_exit
    return 0
}
