# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: Planck
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=HEAD
local address="http://pla.esac.esa.int/pla-sl/data-action?COSMOLOGY.COSMOLOGY_OID"
local location="${pkgman_install_dir}/clik"
local data="${pkgman_install_dir}/../data/planck_data"

function planck::dump()
{
    pkgtools__msg_notice "planck"
    pkgtools__msg_notice " |- to      : ${location}"
    pkgtools__msg_notice " |- data    : ${data}"
    pkgtools__msg_notice " \`- from    : ${address}"
}

function planck::install()
{
    (
        pkgman setup python2
        cd $(mktemp -d)
        wget "${address}=1904" -O planck_code.tar.bz2
        tar xjvf planck_code.tar.bz2
        mkdir -p ${location}
        mv plc-2.0/* ${location}/.
        rm -rf $(pwd)

        cd ${location}
        local waf_options="--install_all_deps "
        if $(pkgtools__has_binary icc); then
            waf_options+="--icc --ifort "
        elif $(pkgtools__has_binary gcc); then
            waf_options+="--gcc --gfortran "
        fi
        if $(pkgtools__check_variable MKLROOT); then
            waf_options+="--lapack_mkl=$MKLROOT"
        fi
        ./waf configure $(echo ${waf_options})
        ./waf install

        if [ ! -d ${data} ]; then
            mkdir -p ${data}
            cd $(mktemp -d)
            wget "${address}=1900" -O planck_data.tar.gz
            tar xzvf planck_data.tar.gz
            mv plc_2.0/* ${data}/.
            rm -rf $(pwd)
        fi
    )
}

function planck::uninstall()
{
    pkgtools__msg_warning "Do you really want to remove planck ?"
    pkgtools__yesno_question
    if $(pkgtools__answer_is_yes); then
        rm -rf ${location}
    fi
}

function planck::setup()
{
    pkgtools__add_path_to_LD_LIBRARY_PATH ${location}/lib
    pkgtools__set_variable CLIKDIR ${location}
    pkgtools__set_variable PLANCK_DATA ${data}
}

function planck::unsetup()
{
    pkgtools__remove_path_to_LD_LIBRARY_PATH ${location}/lib
    pkgtools__unset_variable CLIKDIR
    pkgtools__unset_variable PLANCK_DATA
}
