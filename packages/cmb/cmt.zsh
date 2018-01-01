# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMT
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=v1r26
local address="http://www.cmtsite.net/${version}/CMT${version}.tar.gz"
local location="${pkgman_install_dir}/CMT/${version}"

function cmt::dump()
{
    pkgtools::at_function_enter cmt::dump
    pkgtools::msg_notice "CMT"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
    pkgtools::at_function_exit
    return 0
}

function cmt::install()
{
    pkgtools::at_function_enter cmt::install
    (
        mkdir -p ${location}
        cd $(mktemp -d)
        wget ${address}
        tar xzvf CMT${version}.tar.gz
        cp -r CMT/${version}/* ${location}
        rm -rf $(pwd)
        cd ${location}/mgr
        ./INSTALL && source setup.sh && make
    )
    pkgtools::at_function_exit
    return 0
}

function cmt::uninstall()
{
    pkgtools::at_function_enter cmt::uninstall
    pkgtools::msg_warning "Do you really want to delete ${location} ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function cmt::setup()
{
    pkgtools::at_function_enter cmt::setup
    source ${location}/mgr/setup.sh
    pkgtools::reset_variable CMTCONFIG "Linux-x86_64"
    pkgtools::at_function_exit
    return 0
}

function cmt::unsetup()
{
    pkgtools::at_function_enter cmt::unsetup
    if ! $(pkgtools::check_variable CMTROOT); then
        return 0
    fi

    pkgtools::remove_path_to_PATH ${CMTROOT}/${CMTBIN}
    pkgtools::unset_variable CMTROOT
    pkgtools::unset_variable CMTBIN
    pkgtools::unset_variable CMTCONFIG
    pkgtools::unset_variable CLASSPATH
    pkgtools::unset_variable jmct
    pkgtools::unset_variable cmt
    pkgtools::unset_variable MAKEFLAGS
    unalias cmt
    unfunction cmt_actions cmt_default_path cmt_make cmt_aliases cmt_fragments \
               cmt_patterns cmt_constituents cmt_macros cmt_sets
    pkgtools::at_function_exit
    return 0
}
