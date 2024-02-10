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

# Extras
APPS="Y"                              # "Y" or "N" install personal applications from github repo (https://github.com/Stu-Air/arch-apps)
SETTINGS="Y"                          # "Y" or "N" install personal dotfiles from github repo (https://github.com/Stu-Air/dotfiles)
DESKTOP="gnome"                       # kde, xfce or gnome desktop, login manager installed also 

# Choose your video driver
    
#VIDEO_DRIVER="i915"                  # For Intel
#VIDEO_DRIVER="nouveau"               # For nVidia
#VIDEO_DRIVER="radeon"                # For ATI
#VIDEO_DRIVER="vesa"                  # For generic stuff

setup() {   

   local boot_dev="$DRIVE"p1
   local sys_dev="$DRIVE"p2
   
   echo "Connecting to wifi"
   #wifi  (NOT WORKING)
   #iwctl station "$WIRELESS_DEVICE" connect "$WIRELESS_SSID"

   echo "Creating partition tables"
   setPartitions

   echo "Mounting partitions"
   mountPartitions

   echo "Installing base system"
   installBase

   echo 'Chrooting into installed system to continue setup...'
   cp pkglist.txt /mnt
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

    echo 'Installing paru aur helper'
    install_paru

    echo 'Building locate database'
    update_locate

    echo 'Adding your extras'
    extras

    rm /setup.sh
    rm /pkglist.txt
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

    pacman -Sy --noconfirm $CHIPSET
    pacman -Sy --noconfirm - < /pkglist.txt
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
    sudo sh -c 'echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf'
}

install_paru() {
    cd ~ 
    git clone https://aur.archlinux.org/paru-bin.git 
    chown $USER_NAME:$USER_NAME ~
    chmod -R 777 paru-bin
    cd paru-bin
    echo -en "$USER_PASSWORD" |sudo -u $USER_NAME makepkg -si --noconfirm
}

set_root_password() {
    echo -en "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd
}

create_user() {
    useradd -m -G wheel -s /bin/bash $USER_NAME
    echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"
    }
    
extras(){
  if [ "$APPS" = "Y" ]
    then 
        cd ~/Downloads
        git clone https://github.com/Stu-Air/arch-apps.git
        sh arch-apps/./applications.sh
 fi
  if [ "$SETTINGS" = "Y" ]
    then 
        cd ~/Downloads
        git clone https://github.com/Stu-Air/config.git
        sh config/./settings.sh
 fi

#desktop selection (soon to be split into layouts/settings for each)
  if [ "$DESKTOP" = "gnome" ]
    then
        pacman -Sy --noconfirm gnome gdm
 elif [ "$DESKTOP" = "kde" ]
    then
        pacman -Sy --noconfirm plasma sddm
 elif [ "$DESKTOP" = "xfce" ]
    then
        pacman -Sy --noconfirm xfce4 lightdm
 fi
}

if [ "$1" == "chroot" ]
then
    configure
else
    setup
fi
