#! /bin/bash


DRIVE='/dev/nvme0n1'                 # Drive you want to install Arch linux on
HOSTNAME='animus'                     # Hostname of the installed machine
ROOT_PASSWORD=''             # Root password (leave blank to be prompted)
USER_NAME=''                       # Main user to create (by default, added to wheel group, and others)
USER_PASSWORD=''             # The main user's password (leave blank to be prompted)
TIMEZONE=''             # System timezone
KEYMAP=''                           # Keyboard layout used in system 
WIRELESS_DEVICE=""               # Wireless device, leave blank to not use wireless and use DHCP instead
WIRELESS_SSID=""      # Router connection name 
CHIPSET="amd-ucode"                   # amd or intel
DESKTOP=""                       # kde, xfce or gnome  desktop and login manager installed

# Choose your video driver
    
#VIDEO_DRIVER="i915"                  # For Intel
#VIDEO_DRIVER="nouveau"               # For nVidia
#VIDEO_DRIVER="radeon"                # For ATI
#VIDEO_DRIVER="vesa"                  # For generic stuff

setup() {   

   local boot_dev="$DRIVE"p1
   local sys_dev="$DRIVE"p2
   
   echo "Connecting to wifi"
   #wifi

   #iwctl station "$WIRELESS_DEVICE" connect "$WIRELESS_SSID"

   echo "Creating partition tables"
   setPartitions

   echo "Mounting partitions"
   mountPartitions

   echo "Installing base system"
   installBase

   echo 'Chrooting into installed system to continue setup...'
   cp $0 /mnt/setup.sh
   arch-chroot /mnt ./setup.sh chroot

    if [ -f /mnt/setup.sh ]
    then
        echo 'ERROR: Something failed inside the chroot, not unmounting filesystems so you can investigate.'
        echo 'Make sure you unmount everything before you try to run this script again.'
    else
        echo 'Unmounting filesystems'
        unmount_filesystems
        echo 'Done! Reboot system.'
    fi
}


configure() {
    local boot_dev="$DRIVE"p1
    local sys_dev="$DRIVE"p2

    echo 'Installing additional packages'
    install_packages

    echo 'Clearing package tarballs'
    clean_packages

    echo 'Setting hostname'
    set_hostname "$HOSTNAME"

    echo 'Setting timezone'
    set_timezone "$TIMEZONE"

    echo 'Setting locale'
    set_locale

    echo 'Setting console keymap'
    set_keymap

    echo 'Setting hosts file'
    set_hosts "$HOSTNAME"

    echo 'Setting fstab'
    set_fstab

    echo 'Configuring initial ramdisk'
    set_initcpio

    echo 'Setting initial daemons'
    set_daemons

    echo 'Configuring bootloader'
    set_bootloader

    echo 'Configuring sudo'
    set_sudoers

    echo 'Configuring extras'
    set_extras

    echo 'Setting root password'
    set_root_password "$ROOT_PASSWORD"

    echo 'Creating initial user'
    create_user "$USER_NAME" "$USER_PASSWORD"

    echo 'Installing yay aur helper'
    install_yay

    echo 'Installing AUR packages'
    install_aur_packages

    echo 'Building locate database'
    update_locate

    rm /setup.sh
}



wifi(){
   iwctl station "$WIRELESS_DEVICE" connect "$WIRELESS_SSID"
}

setPartitions(){
   (
      echo d # 	Delete existing Partition 
      echo   # 	Accept default
      echo d # 	Delete existing Partition
      echo   # 	Accept default
      echo d # 	Delete existing Partition
      echo   # 	Accept default
      echo d # 	Delete existing Partition
      echo   # 	Accept default
      echo g # 	Create u guid
      echo n # 	Create new partition 
      echo   # 	Accept default
      echo   # 	Accept default
      echo +512M #   Create first partition size 
      echo t # 	Select type of partition 
      echo   # 	Accept default
      echo 1 # 	Partition type 1 (EFI)
      echo   # 	Accept default (Partition 1 created)
      echo n #	Create final partition 
      echo   #	Accept default
      echo   #	Accept default
      echo   #	Accept default (Partition 3 created rest of disk) 
      echo w #	Write to disk 
   ) | fdisk "$DRIVE"

   mkfs.fat -F32 "$boot_dev"	# Make partition 1 Fat format
   mkfs.ext4 "$sys_dev"	        # Make partition 2 Ext4 Format
}

mountPartitions(){
   mount "$sys_dev" /mnt

}

installBase(){
   pacman -Sy --noconfirm archlinux-keyring
   yes '' | pacstrap /mnt base linux-lts linux-firmware linux-lts-headers 
   genfstab -U /mnt >> /mnt/etc/fstab
  
}    

unmount_filesystems() {
   umount /mnt
   umount /boot
}  

install_packages() {
   echo "enable multilib packages"
   echo "[multilib]
   Include = /etc/pacman.d/mirrorlist" | tee -a /etc/pacman.conf


    local packages=''

    # General utilities/libraries
    packages+=' sudo acpi acpid nano wget grub efibootmgr dosfstools os-prober mtools fuse2 rsync  mesa  pulseaudio-bluetooth bluez bluez-utils fuse2 unzip gvfs exfat-utils ntfs-3g' #autofs

    # Development packages
    packages+=' base-devel git gettext jq typescript sassc meson ninja'

    # Netcfg
    packages+=' networkmanager wpa_supplicant wireless_tools netctl dhcpcd dialog'
    
    # Java stuff
    packages+=' '

    # Libreoffice
    packages+=' libreoffice-fresh'

    # Misc programs
    packages+=' htop neofetch bash-completion rclone mpv transmission-gtk thunderbird signal-desktop discord firefox'

    # Xserver
    packages+=' xorg xorg-apps xdg-user-dirs' #xdg-user-dirs-update

    # Slim login manager
    packages+=' '

    # Fonts
    packages+=' '

    # On processors
    packages+=' xf86-video-amdgpu' #"$chipset"

    # For laptops
    packages+=' xf86-input-synaptics'

    
 if [ "$DESKTOP" = "gnome" ]
    then
        packages+=' gnome-desktop gnome-session gnome-control-center gnome-shell-extensions gnome-terminal nautilus gedit file-roller eog gnome-tweaks evince gnome-keyring gdm'
 elif [ "$DESKTOP" = "kde" ]
    then
         packages+='plasma'
 elif [ "$DESKTOP" = "xfce" ]
    then
         packages+='xfce4'
 fi
    pacman -Sy --noconfirm $packages
}


clean_packages() {
    yes | sudo pacman -Rs $(pacman -Qqtd)
}

set_hostname() {
    local hostname="$1"; shift
    echo "$hostname" > /etc/hostname
}

set_timezone() {
    ln -sT "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    hwclock --systohc
}

set_locale() {
    echo 'LANG="en_GB.UTF-8"' >> /etc/locale.conf
    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
}

set_keymap() {
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
}

set_hosts() {
    local hostname="$1"; shift

    cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost $hostname
::1       localhost.localdomain localhost $hostname
EOF
}

set_fstab() {
   echo "configuring swap"
      dd if=/dev/zero of=/swapfile bs=1024 count=524288
      chown root:root /swapfile
      chmod 0600 /swapfile
      mkswap /swapfile
      echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
      swapon -s
   echo "LABEL=Media                                  /mnt/Media   auto   nosuid,nodev,nofail,x-gvfs-show   0 0" | sudo tee -a /etc/fstab
}

set_initcpio() {
   mkinitcpio -P
}

set_daemons() {
   systemctl enable NetworkManager bluetooth gdm
}

set_bootloader() {
   mkdir /boot/efi
   mount "$boot_dev" /boot/efi
   grub-install --target=x86_64-efi efi-directory=/boot/efi
   mkdir /boot/grub/locale
   cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
   grub-mkconfig -o /boot/grub/grub.cfg
}

set_sudoers() {
    echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
}


set_extras() {
  
    ln -sf /mnt/Media/home/Downloads/* ~/Downloads
    mkdir  ~/OneDrive
    ln -sf /mnt/Media/home/Pictures/* ~/Pictures/
    ln -sf /mnt/Media/home/Videos/* ~/Videos/
    mkdir ~/.config/autostart
    ln -sf /mnt/Media/home/.config/autostart/* ~/.config/autostart
    ln -sf /mnt/Media/home/.config/discord ~/.config
    ln -sf /mnt/Media/home/.config/nordvpn ~/.config
    ln -sf /mnt/Media/home/.config/onedrive ~/.config
    ln -sf /mnt/Media/home/.config/plank ~/.config
    ln -sf /mnt/Media/home/.config/rclone ~/.config
    ln -sf /mnt/Media/home/.config/tidal-hifi ~/.config
    ln -sf /mnt/Media/home/.config/transmission ~/.config
    ln -sf /mnt/Media/home/.config/whatsapp-nativefier-d40211 ~/.config
    ln -sf /mnt/Media/home/.fonts ~/
    ln -sf /mnt/Media/home/.minecraft ~/
    ln -sf ~/.minecraft/screenshots ~/Pictures/minecraft-screenshots
    ln -sf /mnt/Media/home/.thunderbird ~/
    sudo ln -sf /mnt/Media/home/Pictures/profile\ pics/profile\ pic.png /var/lib/gdm3/.face
    ln -sf /mnt/Media/home/Pictures/profile\ pics/profile\ pic.png ~/.face   
    ln -sf /mnt/Media/home/.zsh/ ~/
    ln -sf /mnt/Media/home/.zshrc ~/

    sudo sh -c 'echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf'
}

install_yay() {
    cd ~ 
    git clone https://aur.archlinux.org/yay.git 
    chown $USER_NAME:$USER_NAME ~
    chmod -R 777 yay
    cd yay
    sudo -u $USER_NAME makepkg -si --noconfirm
    #pacman -U yay*.zst 
}

install_aur_packages(){
    packages+='dropbox timeshift vscodium-bin minecraft-launcher whatsapp-nativefier'
    echo -en "yay -Sy --noconfirm $packages" |  su "$USER_NAME"
    echo -en "$USER_PASSWORD" | su "$USER_NAME"
    #rm -rf /yay
}


set_root_password() {
    echo -en "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd
}

create_user() {
    useradd -m -G wheel -s /bin/bash $USER_NAME
    echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"
    }



if [ "$1" == "chroot" ]
then
    configure
else
    setup
fi
