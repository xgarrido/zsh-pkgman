# -*- mode: shell-script; -*-
#
# Copyright (C) 2023 Xavier Garrido
#
# Author: garrido@lal.in2p3.fr
# Keywords: raspberry pi
# Requirements: pkgtools
# Status: not intended to be distributed yet

function rpi::dump()
{
  pkgtools::at_function_enter rpi::dump
  pkgtools::at_function_exit
  return 0
}

function rpi::update()
{
  pkgtools::at_function_enter rpi::update
  pkgtools::at_function_exit
  return 0
}

function rpi::install()
{
  pkgtools::at_function_enter rpi::install

  cat <<EOF | sudo tee /etc/systemd/system/media-lacie.automount
[Unit]
Description=Automount lacie disk

[Automount]
Where=/media/lacie

[Install]
WantedBy=multi-user.target
EOF
  cat <<EOF | sudo tee /etc/systemd/system/media-lacie.mount
[Unit]
Description=Lacie

[Mount]
What=/dev/sda1
Where=/media/lacie
Type=ext4

[Install]
WantedBy=multi-user.target
EOF
  systemctl is-enabled media-lacie.mount
  systemctl is-enabled media-lacie.automount
  systemctl start media-lacie.automount
  systemctl daemon-reload

  pkgtools::at_function_exit
  return 0
}

function rpi::uninstall()
{
  pkgtools::at_function_enter rpi::uninstall
  pkgtools::at_function_exit
  return 0
}

function rpi::install_transmission_daemon()
{
  pkgtools::at_function_enter rpi::install_transmission_daemon

  sudo apt -y install transmission-daemon
  sudo mkdir -p /etc/systemd/system/transmission-daemon.service.d
  cat <<EOF | sudo tee /etc/systemd/system/transmission-daemon.service.d/override.conf
[Service]
User=rpi
EOF

  sudo systemctl restart transmission-daemon.service

  pkgtools::at_function_exit
  return 0
}

function rpi::install_syncthing()
{
  pkgtools::at_function_enter rpi::install_syncthing

  # Add the release PGP keys:
  sudo mkdir -p /etc/apt/keyrings
  sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg

  # Add the "stable" channel to your APT sources:
  echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list

  # Update and install syncthing:
  sudo apt-get update
  sudo apt-get -y install syncthing

  # Increase inotify
  echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf

  pkgtools::at_function_exit
  return 0
}

function rpi::install_samba()
{
  pkgtools::at_function_enter rpi::install_samba

  sudo apt install samba

  cat <<EOF | sudo tee /etc/samba/smb.conf2
[share]
   comment = Mount & share media
   path = /media/lacie
   browseable = yes
   read only = yes
   guest ok = yes
EOF

  sudo systemctl restart smbd
  pkgtools::at_function_exit
  return 0
}
