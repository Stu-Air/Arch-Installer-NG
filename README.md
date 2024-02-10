##########
# Arch Linux Install Script NG
# Author: Stuart Kirker ( Stu )
# Version: v2.2, 10-02-2024
# Source: Personal Use
##########



## Description

This is a Shell script for the automation of installing Arch linux. This is by no means any complete set of all Settings needed for your system and neither is it another "antispying" type of script. 
It's simply a installer which I like to use and which in my opinion makes the installation process of Arch Linux on your computer less obtrusive.

THIS SCRIPT INSTALLS ESSENTIAL PROGRAMS AND DEVELOPMENT TOOLS

Added programs from another text files for easy editing of programs.
This script installs :-

Paru AUR helper


## Usage
If you just want to run the script with the default preset, download Arch linux and sig file from (https://www.archlinux.org/download/), 
Verify runing command ( gpg --keyserver-options auto-key-retrieve --verify archlinux-version-x86_64.iso.sig ).
Make sure you edit the top of the section of the script before booting to your Arch live disk. upon booting into the Arch live disk, 
you will need to mount the drive/usb you have the script on and simply run sh ./ArchInstaller.sh

#### In the script my personal drive is an nvme and partitions with a "p" as I'm not sure if other drives show as "sda1". Just be weary of this as changes are needed.

Please feel free to customize & tweak or even add your own custom tweaks, however these features require some basic knowledge of command line usage and shell scripting.

I AM NOT RESPONSIBLE FOR ANY DAMAGE TO YOUR MACHINE. please read carefully and use your head this will wipe and repartition your whole drive.



## Future Tweaks

by all means if anyone has any suggestions I or anyone else can try and add them. 

- [x] adding default settings/applications from another project for each enviroment
- [ ] Link to desktop switcher in https://github.com/Stu-Air/switcher-gnome
- [ ] add on for 24bit audio 

