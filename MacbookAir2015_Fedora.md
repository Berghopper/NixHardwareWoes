# Macbook Air 2015 (MacbookAir7,2) - Fedora 39

Since MacOS Monterey will be EOL by Q4 2024 I decided to try out Fedora 39 on my Macbook Air 2015. I didn't want this thing to hit the landfill just yet, as otherwise it's still a pretty decent machine.

## Post-Install

### RPM Fusion

RPM Fusion is a third-party repo that contains a lot of packages that Fedora won't ship due to licensing issues. However, we'll need it for some of the following steps.

You can follow the instructions here to install it (non-free):

[https://rpmfusion.org/Configuration](https://rpmfusion.org/Configuration)

### BCM4360 WiFi driver and Bluetooth
This is probably by far the most pressing issue. Broadcom has a noted history of not playing nice with Linux.

However, broadcom made a binary driver for related cards, giving us `broadcom-wl`. 
Fedora has `akmod-wl` which is the same, but auto-builds the driver on kernel updates.
This is available in RPM Fusion, so we can simply install it:

```bash
sudo dnf install akmod-wl
```

For sanity, let's remove `b43`, which is included in the kernel:

```bash
sudo dnf remove b43-fwcutter
```

#### Known issues (from own experience):

- 802.11w management frame protection is not supported: Tried this with a 2.4GHz network, and it seems something fails during the handshake.
- 5GHz networks are (not/partially) supported: I've had worse luck on Manjaro before, but it seems to work fine on Fedora. DFS channels will not work, however.
- Bluetooth and 2.4GHz Wifi interfere with each other: BCM4360 is a combo chip, and uses the same antenna for both. Usually drivers include a flag to make the chip switch between BT and Wifi on the same spectrum, but this doesn't seem to be the case here. Best solution is to use 5GHz Wifi when possible.
- Random disconnects: I've had this happen a few times, It seems to happen more often when stressing the connection a bit more. Might also happen when trying to use BT with 2.4GHz Wifi anyway.

#### Small note regarding Bluetooth:
[https://discussion.fedoraproject.org/t/bluetooth-audio-becomes-stuttering-while-downloading-or-heavy-use-in-network-data-via-ethernet/74967/5](https://discussion.fedoraproject.org/t/bluetooth-audio-becomes-stuttering-while-downloading-or-heavy-use-in-network-data-via-ethernet/74967/5)

I experiened audio stutters and applied the above listed fix:
```bash
sudo nano /etc/modprobe.d/snd_hda_intel_fix.conf
```
```
options snd_hda_intel power_save=0
options snd_hda_intel power_save_controller=N
```

#### Back to WiFi:

In general, the driver is flaky, but it's the only option we have for this chip as of 2024. Best solution is to use a usb wifi dongle. I opted for a Edimax EW-7822ULC, which has it's own driver here:

[https://github.com/morrownr/88x2bu-20210702](https://github.com/morrownr/88x2bu-20210702)


I got this dongle because it's small, but would recommend getting a better supported one. There's a list of supported devices here:

[https://github.com/morrownr/USB-WiFi](https://github.com/morrownr/USB-WiFi)

#### *But can't you just replace the wifi card?* 
No, you can't. Apple uses a proprietary aiport connector, and the only cards that are compatible are the ones that Apple uses (think different!). There's some adapters out there, but they're mainly for desktop hackintoshes.

If you want some more rage fuel, here's a nice article about reverse engineering broadcom wifi drivers:
- [https://blog.quarkslab.com/reverse-engineering-broadcom-wireless-chipsets.html](https://blog.quarkslab.com/reverse-engineering-broadcom-wireless-chipsets.html)

#### Other Refs:

- [https://wiki.archlinux.org/title/Broadcom_wireless#broadcom-wl](https://wiki.archlinux.org/title/Broadcom_wireless#broadcom-wl)
- [https://wiki.archlinux.org/title/Network_configuration/Wireless#Bluetooth_coexistence](https://wiki.archlinux.org/title/Network_configuration/Wireless#Bluetooth_coexistence)


### Facetime HD camera

Reverse engineered driver can be found here:

[https://github.com/patjak/facetimehd/wiki/Installation#get-started-on-fedora](https://github.com/patjak/facetimehd/wiki/Installation#get-started-on-fedora)

First step is to extract the firmware from the MacOS driver: 
[https://github.com/patjak/facetimehd-firmware.git](https://github.com/patjak/facetimehd-firmware.git)

Then you can install the driver itself via the copr repo

### Keyboard backlight bug

The keyboard backlight works fine, but Gnome 45 has a bug where the event handler will freeze if the backlight is above 40% or so. This seems to be fixed, but not yet released. Just try avoid using the backlight for now :-).

- Issue: [https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7001](https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/7001)
- Fix: [https://gitlab.gnome.org/GNOME/gnome-shell/-/merge_requests/3086](https://gitlab.gnome.org/GNOME/gnome-shell/-/merge_requests/3086)

## Sleep/Suspend

Works fine, but sometimes takes quite a while to resume from suspend. This can vary a lot, but usually resumes within a minute.

## Further tweaks

### mbpfan

This particular Macbook Air likes to fry itself at 100C before it thinks: "oh hey, I should probably use the fan". It then proceeds to go full jet engine until it deems itself 'cool'.
Yeah you got the idea; probably not the best for the HW. You'd be right: https://discussions.apple.com/thread/7565292?sortBy=best

Think different.

mbpfan is a daemon that controls the fan speed on Macbooks. 
It's available in RPM Fusion, so we can just install it:

```bash
sudo dnf install mbpfan
```

You can configure it via `/etc/mbpfan.conf`. I've set it to the following:

```
low_temp = 50
high_temp = 55
max_temp = 80
polling_interval = 1
```

ref: [https://github.com/linux-on-mac/mbpfan](https://github.com/linux-on-mac/mbpfan#usage)

### auto-cpufreq

Nice little tool to help battery life a little by controlling 
CPU frequency.

[https://github.com/AdnanHodzic/auto-cpufreq](https://github.com/AdnanHodzic/auto-cpufreq)
 
I used the following conf:

```bash
cat /etc/auto-cpufreq.conf
```
```
# https://github.com/AdnanHodzic/auto-cpufreq/blob/master/auto-cpufreq.conf-example
# avail governors;
# conservative ondemand userspace powersave performance schedutil 

# 2.9 ghz = max

[charger]
governor = ondemand
# pstate;
energy_performance_preference = performance
# scaling_min_freq = 800000
# scaling_max_freq = 1000000

[battery]
governor = conservative
# pstate;
energy_performance_preference = power
# scaling_min_freq = 800000
scaling_max_freq = 1900000
turbo=auto
```

### Fedora video encodings

Viewing any type of video content? You probably want the codecs from RPM fusion in that case:

[https://rpmfusion.org/Howto/Multimedia](https://rpmfusion.org/Howto/Multimedia)

### Macbook sleep issues
Sleep works completely fine, but you might notice it takes anywhere between 2-3 seconds to a full minute to wake up. The cpu core wake-up might get stuck/be unreseponsive.

You can make a script at `/usr/lib/systemd/system-sleep/fix-macbook-wakeup` to force the cpu cores to go offline/wake-up. This seems to fix the issue:

```bash
#!/bin/sh

switch_cpu () {
    for cpu in $(ls /sys/devices/system/cpu | egrep -i 'cpu[1-9][0-9]?'); do
      echo $1 | sudo tee /sys/devices/system/cpu/$cpu/online > /dev/null;
    done
}

echo "fix macbook wakeup"
case "$1/$2" in
  pre/*)
    echo "going to $2..."       
    switch_cpu 0        
    ;;
  post/*)
    echo "waking up from $2..."
    switch_cpu 1
   ;;
esac
```

`sudo chmod +x /usr/lib/systemd/system-sleep/fix-macbook-wakeup`

Refs:
- [https://discussion.fedoraproject.org/t/disabling-cpu-before-suspend-and-enabling-it-after-wake-up/81890/5](https://discussion.fedoraproject.org/t/disabling-cpu-before-suspend-and-enabling-it-after-wake-up/81890/5)
- [https://discussion.fedoraproject.org/t/wake-up-from-suspend-takes-4-minutes/82194/9](https://discussion.fedoraproject.org/t/wake-up-from-suspend-takes-4-minutes/82194/9)

### Touchpad scroll speed under Gnome

This is a minor tweak, but scrolling speed under Gnome is way to fast by default. They have had an issue open for this for some years now, but after slow discussion they found blockers and this is all still open:

[https://gitlab.gnome.org/GNOME/gtk/-/issues/4793](https://gitlab.gnome.org/GNOME/gtk/-/issues/4793)

However there's a workaround available:

[https://gitlab.com/warningnonpotablewater/libinput-config](https://gitlab.com/warningnonpotablewater/libinput-config)
