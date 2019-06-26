#!/bin/bash

cleanup() {
    rm /chroot.sh
}

update_pacman() {
    echo "[multilib]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    echo "" | sudo tee -a /etc/pacman.conf
    echo "[archlinuxfr]" | sudo tee -a /etc/pacman.conf
    echo "SigLevel = Never" | sudo tee -a /etc/pacman.conf
    echo "Server = http://repo.archlinux.fr/\$arch" | sudo tee -a /etc/pacman.conf
    sudo pacman -Suy
}

set_yay() {
    # Build yay package and install
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si

    # After install, remove the yay build folder
    cd ..; rm -rf yay

    # Sync yay
    yay -Sy
}

set_timezone() {
    sudo tzselect
}

set_thermald() {
    yay -Sy thermald --needed --noconfirm

    # Enable + start
    sudo systemctl enable thermald.service
    sudo systemctl start thermald.service
    sudo systemctl enable thermald
}

set_network() {
    # Install
    yay -S networkmanager network-manager-applet nm-connection-editor --needed --noconfirm

    # Enable + start
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
}


set_sound() {
    # Install pulseaudio packages
    yay -S pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-ctl --needed --noconfirm
}

set_bluetooth() {
    # Install
    yay -S bluez bluez-utils bluez-tools --needed --noconfirm

    # Enable + start
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth

    # (optional) Install nice traybar utils
    yay -S blueman blueberry --needed --noconfirm
}

set_tlp() {
    # Install
    yay -S tlp --needed --noconfirm

    sudo cp tlp /etc/default/tlp

    # Enable + start
    sudo systemctl enable tlp
    sudo systemctl start tlp
    sudo systemctl enable tlp-sleep.service
}

set_xorg() {
    yay -S xorg-server xorg-xev xorg-xinit xorg-xkill xorg-xmodmap xorg-xprop xorg-xrandr xorg-xrdb xorg-xset xinit-xsession --needed --noconfirm

     sudo cp xorg/20-intel.conf /etc/X11/xorg.conf.d/20-intel.conf
    sudo cp xorg/00-keyboard.conf /etc/X11/xorg.conf.d/00-keyboard.conf
    sudo cp xorg/30-touchpad.conf /etc/X11/xorg.conf.d/30-touchpad.conf

    yay -Sy xf86-video-intel --needed --noconfirm

    #yay -Sy evdi displaylink --needed --noconfirm
    #sudo systemctl enable displaylink.service
    #sudo cp xorg/20-evdidevice.conf /etc/x11/xorg.conf.d/20-evdidevice.conf
}

set_i3() {
    yay -Sy i3-gaps-next-git i3lock-fancy-git --needed --noconfirm
    sudo cp .xinitrc ~/.xinitrc
}

set_terminal() {
    yay -Sy alacritty --needed --noconfirm
}

set_extrakeys() {
 # Setup extra keys
sudo echo "evdev:name:ThinkPad Extra Buttons:dmi:bvn*:bvr*:bd*:svnLENOVO*:pn*" | sudo tee /etc/udev/hwdb.d/90-thinkpad-keyboard.hwdb
echo "KEYBOARD_KEY_45=prog1" | sudo tee -a /etc/udev/hwdb.d/90-thinkpad-keyboard.hwdb
echo "KEYBOARD_KEY_49=prog2" | sudo tee -a /etc/udev/hwdb.d/90-thinkpad-keyboard.hwdb
sudo udevadm hwdb --update
sudo udevadm trigger --sysname-match="event*"
}

set_lenovo() {
yay -Sy lenovo-throttling-fix-git
sudo systemctl enable lenovo_fix
sudo systemctl start lenovo_fix
}

disable_camera() {
echo "blacklist uvcvideo" | sudo tee -a /etc/modprobe.d/disable_webcam.conf
}

# exec script
update_pacman
set_yay
set_timezone
set_thermald
set_network
set_sound
set_bluetooth
set_tlp
set_xorg
set_extrakeys
set_lenovo
set_i3
set_terminal
disable_camera
