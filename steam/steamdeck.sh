#!/bin/sh
sudo btrfs property set -ts / ro false
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Syu

# install yay
sudo pacman -S base-devel holo-rel/linux-headers linux-neptune-headers holo-rel/linux-lts-headers git glibc gcc gcc-libs fakeroot linux-api-headers libarchive
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
