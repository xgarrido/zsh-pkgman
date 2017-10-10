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
    pkgtools__msg_notice " |- to      : ${location}"
}

function cmt::install()
{
    if [ ! -d ${location} ]; then
        mkdir -p ${location}
        (
            cd $(mktemp -d)
            wget ${address}
            tar xzvf CMT${version}.tar.gz
            cp -r CMT/${version}/* ${location}
            rm -rf $(pwd)
        )
    fi
    (
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
}
