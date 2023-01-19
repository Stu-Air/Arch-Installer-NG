##########
# Arch Linux Install Script NG
# Author: Stuart Kirker ( Stu )
# Version: v2.0, 19-01-2023
# Source: Personal Use
##########



## Description

This is a Shell script for the automation of installing my personal Arch linux. This is by no means any complete set of all Settings needed for your system and neither is it another "antispying" type of script. 
It's simply a installer which I like to use and which in my opinion makes the installation process of Arch Linux on your computer less obtrusive.

THIS SCRIPT INSTALL ESSENTIAL PROGRAMS AND DEVELOPMENT TOOLS

## Usage
If you just want to run the script with the default preset, download Arch linux and sig file from (https://www.archlinux.org/download/), 
Verify runing command ( gpg --keyserver-options auto-key-retrieve --verify archlinux-version-x86_64.iso.sig ).
Make sure you edit the top of the section of the script before booting to your Arch live disk. upon booting into the Arch live disk, 
you will need to mount the drive/usb you have the script on and simply run sh ./ArchInstaller.sh

#### In the script my personal drive is an nvme and partitions with a "p" as I'm not sure if other drives show as "sda1". Just be weary of this as changes are needed.

Please feel free to customize & tweak or even add your own custom tweaks, however these features require some basic knowledge of command line usage and shell scripting.

I AM NOT RESPONSEABLE FOR ANY DAMAGE TO YOUR MACHINE. please read carefully and use your head this will wipe and repartition your whole drive.



## Future Tweaks

by all means if anyone has any suggestions I or anyone else can try and add them. 

I want to try programs from another text files for easy editing of programs. 

