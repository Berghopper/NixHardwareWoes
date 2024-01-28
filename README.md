# NixHardwareWoes
Personal repo for keeping track of fixes I've had to apply to various hardware running linux.

I'll try to make writeups for whatever I run into.
Mostly that will be specific Distros only as well.

I won't try to be a puritan and only include free software: I just want everything to work, that's it.

Macbook air 2015 (MacbookAir7,2) - Fedora 39 
post-install from this github;

'Barebones' install:
```bash
curl -s https://raw.githubusercontent.com/Berghopper/NixHardwareWoes/main/ma2015fedora.sh | bash
```
Install with 88x2bu chipset (USB WiFi); [https://github.com/morrownr/88x2bu-20210702](https://github.com/morrownr/88x2bu-20210702)
```bash
curl -s https://raw.githubusercontent.com/Berghopper/NixHardwareWoes/main/ma2015fedora_usb.sh | bash ```