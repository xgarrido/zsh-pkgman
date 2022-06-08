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
    black
    bump2version
    camb
    cobaya
    cython
    flake8
    glances
    getdist
    healpy
    ipyleaflet
    ipython
    ipympl
    isort
    jupyter
    jupyterlab
    jupyterlab-git
    jupyterlab-github
    jupyterlab-notifications
    jupyter-repo2docker
    jupyterlab_code_formatter
    mock
    nbdime
    numpy
    matplotlib
    pandas
    seaborn
    scipy
    pipenv
    plotly
    pre-commit
    pygments
    pygments-solarized
    pylint
    pyside2
    pyyaml
    setuptools
    sidecar
    sphinx
    statsmodels
    tabulate
    twine
    versioneer
    voila
)

local _jlabs=(
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

function pips::update()
{
    pkgtools::at_function_enter pips::update
    pips::install
    pkgtools::at_function_exit
    return 0
}

function pips::install()
{
    pkgtools::at_function_enter pips::install
    pip install --upgrade --user pip wheel
    for ipip in ${_pips}; do
        pkgtools::msg_notice "Installing '${ipip}' via pip..."
        pip install --upgrade --user ${ipip}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "pips update fails !"
            pkgtools::at_function_exit
            return 1
        fi
    done
    # Fix for colout
    pip install --user git+https://github.com/nojhan/colout.git

    for ijlab in ${_jlabs}; do
        pkgtools::msg_notice "Installing '${ijlab}' extension for jupyterlab..."
        jupyter labextension install ${ijlab}
        if $(pkgtools::last_command_fails); then
            pkgtools::msg_error "jlab update fails !"
            pkgtools::at_function_exit
            return 1
        fi
    done
    jupyter serverextension enable --py nbdime --user
    jupyter serverextension enable --py jupyterlab_code_formatter --user
    pkgtools::at_function_exit
    return 0
}

function pips::uninstall()
{
    pkgtools::at_function_enter pips::uninstall
    pkgtools::msg_warning "Do you really want to uninstall pip packages ?"
    pkgtools::yesno_question
    if $(pkgtools::answer_is_yes); then
        pip uninstall --yes $(eval print -l ${_pips})
    fi
    pkgtools::at_function_exit
    return 0
}
