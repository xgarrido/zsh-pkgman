# -*- mode: shell-script; -*-
#
# Copyright (C) 2019 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: archlinux
# Requirements: pkgtools
# Status: not intended to be distributed yet

local version=null
local _pkgs=(
  acpi
  alsa-utils
  arc-gtk-theme
  aspell-fr
  aspell-en
  autofs
  bat
  bzip2
  cblas
  ccache
  cfitsio
  cmake
  cronie
  cups
  diff-so-fancy
  dmenu
  docker
  docker-compose
  dropbox
  dunst
  exa
  fasd
  freerdp
  gcc-fortran
  gcolor2
  gdb
  google-chrome
  gnuplot
  go
  gparted
  gmime
  hsetroot
  imagemagick
  inetutils
  jq
  lapack
  lxappearance
  mattermost-desktop
  meld
  mplayer
  mu
  net-tools
  ncurses
  network-manager-applet
  ngrok-bin
  ninja
  npm
  numix-icon-theme-git
  offlineimap
  openbox
  openbox-arc-git
  openssh
  openntpd
  owncloud-client
  pacman-contrib
  pandoc-bin
  perl-term-readkey
  pdf2svg
  python-pip
  pyenv
  pstoedit
  remmina
  ruby
  ruby-irb
  rsync
  slack-desktop
  syncthing-gtk
  subversion
  terminator
  scrot
  sshfs
  texlive-basic
  texlive-bibtexextra
  texlive-bin
  texlive-binextra
  texlive-fontsextra
  texlive-fontsrecommended
  texlive-formatsextra
  texlive-games
  texlive-humanities
  texlive-langfrench
  texlive-langgreek
  texlive-latex
  texlive-latexextra
  texlive-latexrecommended
  texlive-mathscience
  texlive-music
  texlive-pictures
  texlive-plaingeneric
  texlive-pstricks
  texlive-publishers
  texlive-xetex
  tint2
  tk
  the_silver_searcher
  transmission-remote-gtk
  tree
  ttf-inconsolata
  ttf-ubuntu-font-family
  ttf-font-awesome
  xapian-core
  xclip
  xdotool
  xorg-xrandr
  xorg-xinput
  xorg-xinit
  wmctrl
  wget
  zoom
)

function pkgs::dump()
{
  pkgtools::at_function_enter pkgs::dump
  for ipkg in ${_pkgs}; do
    echo " ➜ ${ipkg}: $(yaourt -Si ${ipkg} | grep '^Version' | awk '{print $3}')"
  done
  pkgtools::at_function_exit
  return 0
}

function pkgs::install()
{
  pkgtools::at_function_enter pkgs::install
  local pkg_options="-S --noconfirm --needed"
  if ! $(pkgtools::has_binary g++); then
    sudo pacman ${=pkg_options} base-devel
  fi
  if ! $(pkgtools::has_binary git); then
    sudo pacman ${=pkg_options} git
  fi
  if ! $(pkgtools::has_binary yaourt); then
    (
      cd $(mktemp -d)
      git clone https://aur.archlinux.org/package-query.git
      cd package-query
      makepkg -si --noconfirm
      cd ..
      git clone https://aur.archlinux.org/yaourt.git
      cd yaourt
      makepkg -si --noconfirm
      cd ..
      rm -rf $(pwd)
    )
  fi
  # Add GPG for dropbox
  gpg --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
  for ipkg in ${_pkgs}; do
    pkgtools::msg_notice "Installing '${ipkg}' via yaourt..."
    yaourt ${=pkg_options} ${ipkg}
  done

  pkgtools::msg_notice "Post-action like enabling service"
  sudo systemctl enable openntpd.service
  sudo systemctl start  openntpd.service
  pkgtools::at_function_exit
  return 0
}

function pkgs::uninstall()
{
  pkgtools::at_function_enter pkgs::uninstall
  pkgtools::msg_warning "Do you really want to uninstall arch packages ?"
  pkgtools::yesno_question
  if $(pkgtools::answer_is_yes); then
    yaourt -R $(eval print -l ${_pkgs})
  fi
  pkgtools::at_function_exit
  return 0
}
