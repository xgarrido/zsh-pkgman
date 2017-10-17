# -*- mode: shell-script; -*-
#
# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: CMB
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=master
local cmb_pkgs=(python2 cmt class pypico planck camel)

case $(hostname) in
    cca*)
        pkgman_install_dir=$SCRATCH_DIR/workdir/cmb/software
        ;;
    *)
        pkgman_install_dir=$HOME/Workdir/CMB/software
        ;;
esac

function --cmb::action()
{
    for ipkg in ${cmb_pkgs}; do
        pkgman $@ ${ipkg}
    done
}

function cmb::dump()
{
    --cmb::action dump $@
}

function cmb::install()
{
    --cmb::action install $@
}

function cmb::uninstall()
{
    --cmb::action uninstall $@
}

function cmb::setup()
{
    --cmb::action setup $@
}

function cmb::unsetup()
{
    --cmb::action unsetup $@
}
