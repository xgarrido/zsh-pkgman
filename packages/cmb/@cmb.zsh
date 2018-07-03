# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMB
# Requirements: pkgtools
# Status: not intended to be distributed yet

local cmb_pkgs=(python2 pypico cmt class cfitsio planck camel healpix camb s2hat xpol)

function cmb::at_cc()
{
    [[ $(hostname) == cc* ]] && return 0 || return 1
}

if $(cmb::at_cc); then
    pkgman_install_dir=/sps/planck/camel/CentOS7/software
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
    --cmb::action install $@
    if $(pkgtools::last_command_fails); then
        pkgtools::at_function_exit
        return 1
    fi
    local readme=${pkgman_install_dir}/../README
    cat << EOF > ${readme}

    The following directory ${pkgman_install_dir}/.. holds softwares for CMB analysis which
    installation has been performed by pkgman script utility
    (https://github.com/xgarrido/zsh-pkgman). All the installation recipes can be viewed in
    https://github.com/xgarrido/zsh-pkgman/tree/master/packages/cmb.

    Below is a list of installed softwares with their associated version.

EOF
    cmb::dump >> ${readme} 2>&1
    sed -i -e 's#\(^.*NOTICE: \)\(.*dump: \)\(.*\)#\3#' -e 's#\(^[A-Za-z]\)\(.*\)#- \1\2#' ${readme}

    cat << EOF >> ${readme}

Automatically done $(date)
EOF
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
