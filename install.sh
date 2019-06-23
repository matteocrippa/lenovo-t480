#!/bin/bash

# env variables
. vars.sh

# wipe
wipe() {
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $NVME
  x # expert mode
  z # wipe disk
  y # confirm
  y # confirm
EOF

# prepare ssd
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $SSD
  x # expert mode
  z # wipe disk
  y # confirm
  y # confirm
EOF
}


while true; do
    read -p 'do you want to wipe the disk "y" or "n": ' yn

    case $yn in

        [Yy]* ) wipe; break;;

        [Nn]* ) break;;

        * ) echo 'Please answer yes or no: ';;

    esac
done

# partition
partition() {
# format disk ssd for home
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $SSD
  o # clear the in memory partition table
  y # confirm cleanup
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk
    # 100 MB boot parttion
  8E00 # filesystem type
  w # write the partition table
  y # confirm
EOF

# format disk nvme for swap and root
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $NVME
  o # clear the in memory partition table
  y # confirm cleanup
  n # new partition
  1 # partition number 1
    # default - start at beginning of disk
  +256MB # 100 MB boot parttion
  EF00
  n # new partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  8E00 # make a partition bootable
  w # write the partition table
  y # confirm
EOF
}


while true; do
    read -p 'do you want to partition the disk "y" or "n":  ' cc

    case $cc in

        [Yy]* ) partition; break;;

        [Nn]* ) break;;

        * ) echo 'Please answer yes or no: ';;

    esac
done

# format
format() {
# NvMe
mkfs.fat ${NVME}p1

cryptsetup luksFormat -v -s 512 -h sha512 ${NVME}p2
cryptsetup luksOpen ${NVME}p2 luks
pvcreate ${NVME}p2 ${LUKS}
vgcreate ${VG} ${LUKS}
lvcreate -L${SWAP_SIZE} ${VG} -n ${SWAP}
lvcreate -l 100%FREE ${VG} -n ${ROOT}
mkfs.ext4 /dev/mapper/${VG}-${ROOT}
mkswap /dev/mapper/${VG}-${SWAP}

# SSD
dd if=/dev/urandom of=keyfile bs=1024 count=20
cryptsetup --key-file keyfile luksFormat ${SSD}1
cryptsetup --key-file keyfile luksOpen ${SSD}1 ssd
pvcreate /dev/mapper/ssd
vgcreate ssd_group /dev/mapper/ssd
lvcreate -l 100%FREE ssd_group -n home
mkfs.ext4 /dev/mapper/ssd_group-home

## NvME
mount /dev/mapper/${VG}-${ROOT} /mnt
cp keyfile /mnt
umount -R /mnt
}

# wifi setup
wifi() {
    wifi-menu
}

# mount
mountall() {
    mount /dev/mapper/${VG}-${ROOT} /mnt
    mkdir /mnt/boot
    mount ${NVME}p1 /mnt/boot
    mkdir /mnt/home
    mount /dev/mapper/ssd_group-home /mnt/home
    swapon /dev/mapper/${VG}-${SWAP}
}

# pacstrap
prepare() {
    dirmngr </dev/null
    pacman-key --populate archlinux
    pacman-key --refresh-keys
    pacstrap /mnt base base-devel dialog openssl-1.0 bash-completion git intel-ucode wpa_supplicant
    genfstab -pU /mnt >> /mnt/etc/fstab
}

# chroot
chrootall() {
    cp chroot.sh /mnt

    # chroot arch
    arch-chroot /mnt /bin/bash
    umount -R /mnt
    reboot
}

format
mountall
prepare
chrootall
