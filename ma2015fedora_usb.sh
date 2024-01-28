#!/bin/bash

# This script is for setting up a fresh Fedora 39 install on a Macbook Air 2015

# set up mpbfan for fan control, prevent overheating
sudo dnf install -y mbpfan
sudo systemctl enable mbpfan
sudo systemctl stop mbpfan
echo "low_temp = 50
high_temp = 55
max_temp = 80
polling_interval = 1" | sudo tee /etc/mbpfan.conf
sudo systemctl start mbpfan

# upgrade fedora
sudo dnf upgrade -y

# setup rpmfusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager -y --enable fedora-cisco-openh264
# setup rpmfusion codecs
# https://rpmfusion.org/Howto/Multimedia
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate -y sound-and-video

# install some dependencies
# NOTE: we'll use dkms in some cases, even though fedora has akmod. dkms is more flexible
sudo dnf install -y git kernel-devel kernel-headers make gcc dkms libudev-devel libinput-devel meson unrar

# set up broadcom-wl for BCM4360; akmod-wl builds the module for the current kernel
sudo dnf install -y akmod-wl
# remove old wifi drivers
sudo dnf remove -y b43-fwcutter
## also install usb wifi drivers (RTL88x2BU-Linux-Driver)
# Clone the RTL88x2BU driver repository
cd ~/
git clone https://github.com/RinCat/RTL88x2BU-Linux-Driver.git
cd RTL88x2BU-Linux-Driver
# Add the driver to dkms and build it
sudo dkms add .
sudo dkms install -m 88x2bu -v 1.0
# Load the driver module
sudo modprobe -r wl
sudo modprobe 88x2bu
##
# now blacklist all other wifi drivers
sudo echo "blacklist b43
blacklist brcmfmac
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_core
blacklist wl" | sudo tee /etc/modprobe.d/wifi-blacklist.conf
# small bluetooth fix
sudo echo "options snd_hda_intel power_save=0
options snd_hda_intel power_save_controller=N" | sudo tee /etc/modprobe.d/snd_hda_intel_fix.conf
## FaceTime HD Camera as DKMS module
# Clone the facetimehd firmware extractor repository
cd ~/
git clone https://github.com/patjak/facetimehd-firmware.git
cd facetimehd-firmware
make -j $(nproc)
sudo make install
# download the sensor calibration files
# https://support.apple.com/kb/DL1837
cd ~/
https://download.info.apple.com/Mac_OS_X/031-30890-20150812-ea191174-4130-11e5-a125-930911ba098f/bootcamp5.1.5769.zip
unzip bootcamp5.1.5769.zip -d bootcamp5.1.5769
cd bootcamp5.1.5769/BootCamp/Drivers/Apple
unrar x AppleCamera64.exe
dd bs=1 skip=1663920 count=33060 if=AppleCamera.sys of=9112_01XX.dat
dd bs=1 skip=1644880 count=19040 if=AppleCamera.sys of=1771_01XX.dat
dd bs=1 skip=1606800 count=19040 if=AppleCamera.sys of=1871_01XX.dat
dd bs=1 skip=1625840 count=19040 if=AppleCamera.sys of=1874_01XX.dat
sudo cp ./*_01XX.dat /lib/firmware/facetimehd/
# install copr repo for facetimehd driver
echo 'install_items+=" /usr/lib/firmware/facetimehd/firmware.bin "' | sudo tee -a /etc/dracut.conf.d/facetimehd.conf
sudo dnf copr enable -y frgt10/facetimehd-dkms
sudo dnf install -y facetimehd
sudo modprobe facetimehd
# tweak touchpad scrolling, by default it's too fast
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
echo 'scroll-factor=0.175' | sudo tee -a /etc/libinput.conf
cd ~/
git clone https://gitlab.com/warningnonpotablewater/libinput-config.git
cd libinput-config
meson build
cd build
ninja
sudo ninja install
## auto-cpufreq for power management (last step, manual input required)
echo "# https://github.com/AdnanHodzic/auto-cpufreq/blob/master/auto-cpufreq.conf-example
# avail governors;
# conservative ondemand userspace powersave performance schedutil 

# 2.9 ghz = max

[charger]
governor = ondemand
# pstate;
energy_performance_preference = performance
# scaling_min_freq = 800000
scaling_max_freq = 2700000

[battery]
governor = conservative
# pstate;
energy_performance_preference = power
# scaling_min_freq = 800000
scaling_max_freq = 1900000
turbo=auto
" | sudo tee /etc/auto-cpufreq.conf
cd ~/
git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq
yes yes | sudo ./auto-cpufreq-installer --install
# also install the actual service
sudo auto-cpufreq --install
## remove Network await during boot
sudo systemctl mask NetworkManager-wait-online.service


## create info file on this post-install script
SUMMARY_FILE=~/Desktop/system_config_summary.txt

# Write system configuration and driver status to the file
{
    echo "Installed Drivers"
    echo "-----"
    echo "akmod-wl (Broadcom BCM4360)"
    echo "RTL88x2BU-Linux-Driver (USB Wifi)"
    echo "facetimehd (FaceTime HD Camera)"
    echo "---------------------------------------------"
    echo "Installed Configurations:"
    echo "-----"
    echo "mbpfan (Fan Control):"
    echo "/etc/mbpfan.conf"
    echo "auto-cpufreq (CPU Power Management):"
    echo "/etc/auto-cpufreq.conf"
    echo "libinput-config (Touchpad Scrolling Fix):"
    echo "/etc/libinput.conf"
    echo "---------------------------------------------"
    echo "Disabled Drivers:"
    echo "-----"
    echo "b43 brcmfmac rtw88_8822bu rtw88_usb rtw88_core wl"
    echo "see: /etc/modprobe.d/wifi-blacklist.conf"
    echo "---------------------------------------------"
    echo "Disabled Services:"
    echo "-----"
    echo "NetworkManager-wait-online.service"
    echo "---------------------------------------------"
    echo "Downloaded Files/Repos:"
    echo "-----"
    echo "~/RTL88x2BU-Linux-Driver"
    echo "~/facetimehd-firmware"
    echo "~/bootcamp5.1.5769.zip"
    echo "~/bootcamp5.1.5769"
    echo "~/libinput-config"
    echo "~/auto-cpufreq"
    echo "---------------------------------------------"
    echo "Additional Notes:"
    echo "-----"
    echo "broadcom-wl drivers are included but disabled, it's assumed you have the USB wifi dongle noted in the README"
    echo ""
    echo "some bluetooth device power management is disabled, as it might cause issues with bluetooth audio"
    echo "see: /etc/modprobe.d/snd_hda_intel_fix.conf"
} > "$SUMMARY_FILE"

cd ~/

less "$SUMMARY_FILE"