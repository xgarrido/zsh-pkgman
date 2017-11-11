# Copyright (C) 2017 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: archlinux
# Requirements: pkgtools
# Status: not intended to be distributed yet

if ! $(pkgtools__has_binary apt-get); then
    pkgtools__msg_error "Not an ubuntu flavour distribution!"
    __pkgtools__at_function_exit
    return 1
fi
