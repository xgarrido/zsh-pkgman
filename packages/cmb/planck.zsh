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
    pkgtools::at_function_enter planck::dump
    pkgtools::msg_notice "planck"
    pkgtools::msg_notice " |- from    : ${address}"
    pkgtools::msg_notice " |- to      : ${location}"
    pkgtools::msg_notice " \`- data    : ${data}"
    pkgtools::at_function_exit
    return 0
}

function planck::install()
{
    pkgtools::at_function_enter planck::install
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
        pkgman setup cfitsio
        waf_options+="--cfitsio_include=${CFITSIO_INCLUDE} --cfitsio_lib=${CFITSIO_LIB} "
        if $(pkgtools::has_binary icc); then
            waf_options+="--icc --ifort "
            # Patches
            sed -i -e 's/openmp/qopenmp/g' waf_tools/try_icc.py waf_tools/try_ifort.py
        elif $(pkgtools::has_binary gcc); then
            waf_options+="--gcc --gfortran "
        fi
        if $(pkgtools::check_variable MKLROOT); then
            waf_options+="--lapack_mkl=$MKLROOT"
        fi
        ./waf configure $(echo ${waf_options})
        ./waf install
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "Installation of planck software fails!"
            pkgtools::at_function_exit
            return 1
        fi
        if $(cmb::at_cc); then
            # Fix clik-config
            sed -i -e 's#cflags = "\(.*\)#cflags = "-I'${location}'/include \1#g' bin/clik-config
            sed -i -e 's#-lcfitsio##' \
                -e 's#libs = "\(.*\)\(-Wl,-rpath,'${CFITSIO_LIB}'\)\(.*\)\(-L'${CFITSIO_LIB}'\)\(.*\)#libs = "\2 \4 -lcfitsio \1\3\5#g' \
                bin/clik-config
        else
            sed -i -e 's#\(-Wl,-Bdynamic.*'${location}'/lib\)\(.*\)\(-Wl,-rpath,'${location}'\)\(.*\)\(-L'${location}'\)#\2\3/lib\4\5/lib#g' bin/clik-config
        fi

        if [ ! -d ${data} ]; then
            mkdir -p ${data}
            cd $(mktemp -d)
            wget "${address}=1900" -O planck_data.tar.gz
            tar xzvf planck_data.tar.gz
            mv plc_2.0/* ${data}/.
            rm -rf $(pwd)
        fi
    )
    pkgtools::at_function_exit
    return 0
}

function planck::uninstall()
{
    pkgtools::at_function_enter planck::uninstall
    pkgtools::msg_warning "Do you really want to remove planck ?"
    pkgtools::yesno_question "Answer ?"
    if $(pkgtools::answer_is_yes); then
        rm -rf ${location}
    fi
    pkgtools::at_function_exit
    return 0
}

function planck::setup()
{
    pkgtools::at_function_enter planck::setup
    pkgtools::msg_notice -n "Configuring planck..."
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::add_path_to_LD_LIBRARY_PATH ${location}/lib
    pkgtools::set_variable CLIKDIR ${location}
    pkgtools::set_variable PLANCK_DATA ${data}
    pkgtools::at_function_exit
    return 0
}

function planck::unsetup()
{
    pkgtools::at_function_enter planck::unsetup
    pkgtools::msg_notice -n "Unconfiguring planck..."
    pkgtools::msg_color_green; echo "\033[3D ➜ done"; pkgtools::msg_color_normal
    pkgtools::remove_path_to_LD_LIBRARY_PATH ${location}/lib
    pkgtools::unset_variable CLIKDIR
    pkgtools::unset_variable CLIKLIBS
    pkgtools::unset_variable CLIKCFLAGS
    pkgtools::unset_variable PLANCK_DATA
    pkgtools::at_function_exit
    return 0
}
