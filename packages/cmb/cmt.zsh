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
    pkgtools__msg_notice "CMT"
    pkgtools__msg_notice " |- version : ${version}"
    pkgtools__msg_notice " |- from    : ${address}"
    pkgtools__msg_notice " \`- to      : ${location}"
}

function cmt::install()
{
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
}

function cmt::uninstall()
{
    pkgtools__msg_warning "Do you really want to delete ${location} ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
       rm -rf ${location}
    fi
}

function cmt::setup()
{
    source ${location}/mgr/setup.sh
    pkgtools__set_variable CMTCONFIG "Linux-x86_64"
}

function cmt::unsetup()
{
    if ! $(pkgtools__check_variable CMTROOT); then
        return 0
    fi

    pkgtools__remove_path_to_PATH ${CMTROOT}/${CMTBIN}
    pkgtools__unset_variable CMTROOT
    pkgtools__unset_variable CMTBIN
    pkgtools__unset_variable CMTCONFIG
    pkgtools__unset_variable CLASSPATH
    pkgtools__unset_variable jmct
    pkgtools__unset_variable cmt
    pkgtools__unset_variable MAKEFLAGS
    unalias cmt
    unfunction cmt_actions cmt_default_path cmt_make cmt_aliases cmt_fragments \
               cmt_patterns cmt_constituents cmt_macros cmt_sets
}
