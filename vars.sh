#!/bin/bash

# env variables

export NVME=/dev/nvme0n1
export SSD=/dev/sda
export LUKS=/dev/mapper/luks
export SWAP_SIZE=24G
export SWAP=swap
export ROOT=root
export VG=rootvg
export HOSTNAME=earth
export TIMEZONE=/Europe/Rome
export USER=matteo
export BOOT_CFG=/boot/loader/entries/arch.conf
export HOOKS="HOOKS=(base udev autodetect modconf block sd-vconsole keymap keyboard encrypt lvm2 filesystems fsck systemd)"

