# -*- mode: shell-script; -*-
#
# Copyright (C) 2019 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: archlinux
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=null
local _pips=(
    glances
    camb
    cobaya
    cython
    ipython
    jupyter
    jupyter-repo2docker
    numpy
    matplotlib
    pandas
    seaborn
    scipy
    pipenv
    pygments
    pyyaml
)

function pips::dump()
{
    pkgtools::at_function_enter pips::dump
    for ipip in ${_pips}; do
        echo -ne " ➜ ${ipip}"
        if $(pkgtools::has_binary pip); then
            echo ": $(pip show ${ipip} | grep '^Version' | awk '{print $2}')"
        fi
    done
    pkgtools::at_function_exit
    return 0
}

function pips::install()
{
    pkgtools::at_function_enter pips::install
    for ipip in ${_pips}; do
        pkgtools::msg_notice "Installing '${ipip}' via pip..."
        pip install --upgrade --user ${ipip}
    done
    # Fix for colout
    pip install --user git+https://github.com/nojhan/colout.git
    pkgtools::at_function_exit
    return 0
}

function pips::uninstall()
{
    pkgtools::at_function_enter pips::uninstall
    pkgtools::msg_warning "Do you really want to uninstall pip packages ?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        pip uninstall $(eval print -l ${_pips})
    fi
    pkgtools::at_function_exit
    return 0
}