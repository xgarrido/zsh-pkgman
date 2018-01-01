# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMT
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=v2.4.4
local address="https://github.com/lesgourg/class_public/archive"
local location="${pkgman_install_dir}/class/${version}"

function class::dump()
{
    pkgtools::msg_notice "CLASS"
    pkgtools::msg_notice " |- version : ${version}"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " \`- to      : ${location}"
}

function class::install()
{
    (
        pkgman setup cmt
        cd $(mktemp -d)
        wget ${address}/${version}.tar.gz
        tar xzvf ${version}.tar.gz
        mkdir -p ${location}
        mv class_public-${version/v/}/* ${location}/.
        rm -rf $(pwd)

        cd ${location}/../..
        cmt create class ${version}
        cd ${location}/cmt
        if $(pkgtools::has_binary icc); then
            [[ ! -f requirements-class-icc.txt ]] && \
                wget http://camel.in2p3.fr/wiki/uploads/Main/requirements-class-icc.txt
            sed -i -e 's#-openmp#-qopenmp -qoverride-limits#' requirements-class-icc.txt
            sed -i -e 's#/afs/in2p3.fr/.*-liomp5#'$(dirname $(which icc))'/../../lib/intel64 -liomp5#' requirements-class-icc.txt
            rm -f requirements; ln -sf requirements-class-icc.txt requirements
        elif $(pkgtools::has_binary gcc); then
            [[ ! -f requirements-class-gcc.txt ]] && \
                wget http://camel.in2p3.fr/wiki/uploads/Main/requirements-class-gcc.txt
            rm -f requirements; ln -sf requirements-class-gcc.txt requirements
        fi
        cmt config
        make
        cd ${location}/..
        ln -sf ${version} HEAD
    )
}

function class::uninstall()
{
    pkgtools::msg_warning "Do you really want to delete ${location} ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
       rm -rf ${location}
    fi
}

function class::setup()
{
    pkgtools::set_variable CMTCLASS ${pkgman_install_dir}
}

function class::unsetup()
{
    pkgtools::unset_variable CMTCLASS
}
