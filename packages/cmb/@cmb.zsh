# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMB
# Requirements: pkgtools
# Status: not intended to be distributed yet

local cmb_pkgs=(python2 pypico cmt class cfitsio planck camel healpix camb s2hat xpol)

if $(pkgtools::at_cc); then
    pkgman_install_dir=/sps/planck/camel/CentOS7/software
    #pkgman_install_dir=/sps/nemo/scratch/garrido/workdir/cmb/software
else
    pkgman_install_dir=$HOME/Workdir/CMB/software
    # Remove non compiling software
    cmb_pkgs=("${(@)cmb_pkgs:#s2hat}")
    cmb_pkgs=("${(@)cmb_pkgs:#xpol}")
fi

function --cmb::action()
{
    pkgtools::at_function_enter --cmb::action
    for ipkg in ${cmb_pkgs}; do
        pkgman $@ ${ipkg}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Something fails when applying '$@' action to '${ipkg}'!"
            pkgtools::at_function_exit
            return 1
        fi
    done
    pkgtools::at_function_exit
    return 0
}

function cmb::dump()
{
    pkgtools::at_function_enter cmb::dump
    --cmb::action dump $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function cmb::install()
{
    pkgtools::at_function_enter cmb::install
    # Make sure icc/ifort are not in the path
    if $(pkgtools::has_binary icc); then
        pkgtools::msg_error "Intel compilers are within your PATH!"
        pkgtools::msg_error "Remove them to make sure the CMB software suite can be installed."
        return 1
    fi

    --cmb::action install $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi

    pkgtools::msg_notice "Generate README file..."
    local readme=${pkgman_install_dir}/README
    cat << EOF > ${readme}

    The following directory ${pkgman_install_dir}/.. holds softwares for CMB analysis which
    installation has been performed by pkgman script utility
    (https://github.com/xgarrido/zsh-pkgman). All the installation recipes can be viewed in
    https://github.com/xgarrido/zsh-pkgman/tree/master/packages/cmb.

    To load all the software, you may source the startup scripts cmb_setup.sh or cmb_setup.csh
    depending of your shell flavor.

    Below is a list of installed softwares with their associated version.

EOF
    cmb::dump >> ${readme} 2>&1
    sed -i -e 's#\(^.*NOTICE: \)\(.*dump: \)\(.*\)#\3#' -e 's#\(^[A-Za-z]\)\(.*\)#- \1\2#' ${readme}

    cat << EOF >> ${readme}

Automatically done $(date)
EOF
    pkgtools::msg_notice "Generate startup scripts..."
    local startup_sh="# Automatic startup script - do not edit!\n"
    local startup_csh="# Automatic startup script - do not edit!\n"
    for ipkg in ${cmb_pkgs}; do
        local pkg_file=$(find ${pkgman_dir}/packages -name ${ipkg}.zsh)
        . ${pkg_file}
        startup_sh+="\n# $ipkg setup\n"
        startup_csh+="\n# $ipkg setup\n"
        while read line; do
            line=$(sed 's#${pkgman_install_dir}#'${pkgman_install_dir}'#' <<< $line)
            line=$(sed 's#${location}#'${location}'#' <<< $line)
            line=$(sed 's#${data}#'${data}'#' <<< $line)
            line=$(sed 's#${version}#'${version}'#' <<< $line)
            local words=( ${=line} )
            case ${line} in
                *set_variable*)
                    startup_sh+="export ${words[2]}=${words[3]}\n"
                    startup_csh+="setenv ${words[2]} ${words[3]}\n"
                    ;;
                *add_path_to_PATH*)
                    startup_sh+="export PATH=${words[2]}:\$PATH\n"
                    startup_csh+="setenv PATH ${words[2]}:\$PATH\n"
                    ;;
                *add_path_to_LD_LIBRARY_PATH*)
                    startup_sh+="export LD_LIBRARY_PATH=${words[2]}:\$LD_LIBRARY_PATH\n"
                    startup_csh+="setenv LD_LIBRARY_PATH ${words[2]}:\$LD_LIBRARY_PATH\n"
                    ;;
                *enter_directory*)
                    startup_sh+="pushd ${words[2]}\n"
                    startup_csh+="pushd ${words[2]}\n"
                    entering=true
                    ;;
                *exit_directory*)
                    if ${entering}; then
                        startup_sh+="popd\n"
                        startup_csh+="popd\n"
                        entering=false
                    fi
                    ;;
                *source*)
                    startup_sh+="${words[1]} ${words[2]}\n"
                    startup_csh+="${words[1]} ${words[2]}\n"
                    ;;
                *)
                    ;;
            esac
        done <<< $(cat ${pkg_file} | sed -n '/^function.*::setup/,/^}/p')
    done

    echo ${startup_sh} > ${pkgman_install_dir}/cmb_setup.sh
    echo ${startup_csh} > ${pkgman_install_dir}/cmb_setup.csh

    pkgtools::at_function_exit
    return 0
}

function cmb::uninstall()
{
    pkgtools::at_function_enter cmb::uninstall
    --cmb::action uninstall $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function cmb::test()
{
    pkgtools::at_function_enter cmb::test
    --cmb::action test $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::at_function_exit
    return 0
}

function cmb::setup()
{
    pkgtools::at_function_enter cmb::setup
    if [[ ${PKGMAN_SETUP_DONE} = cmb ]]; then
        pkgtools::msg_error "CMB packages are already setup!"
        pkgtools::at_function_exit
        return 1
    elif [[ ! -z ${PKGMAN_SETUP_DONE} ]]; then
        pkgtools::msg_error "Another set of packages (${PKGMAN_SETUP_DONE}) is setup!"
        pkgtools::at_function_exit
        return 1
    fi
    --cmb::action setup $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::reset_variable PKGMAN_SETUP_DONE "cmb"
    pkgtools::at_function_exit
    return 0
}

function cmb::unsetup()
{
    pkgtools::at_function_enter cmb::unsetup
    if [[ ${PKGMAN_SETUP_DONE} != cmb ]]; then
        pkgtools::msg_error "CMB packages are not setup!"
        pkgtools::at_function_exit
        return 1
    fi
    --cmb::action unsetup $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi
    pkgtools::unset_variable PKGMAN_SETUP_DONE
    pkgtools::at_function_exit
    return 0
}
