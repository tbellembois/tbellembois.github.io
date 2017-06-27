# An attempt to configure 2 graphic cards and 3 monitors under Linux 

## Hardware

- an `HP Z420` workstation with 8GB RAM
- an NVidia Quadro 600 card
- an NVidia GeForce7600GS card
- `ArchLinux`
- the [i3](https://i3wm.org) window manager

## Drivers

Following the [ArchLinux](https://wiki.archlinux.org/index.php/NVIDIA) wiki I have tried to install the NVidia proprietary drivers with `yaourt`:
- `nvidia-304xx` for the GeForce card
- `nvidia-352` for the Quadro card

anyway the two drivers can NOT be installed simultaneously. I have then installed the `xf86-video-nouveau` drivers for both cards.

## Xorg configuration

### The devices

You need to write a `device` section PER monitor. Choose a different identifier for each device and enter the same `BusId` for the monitors connected to the same graphic card. Also enter a different `Screen` identifier for each `device`. We will defined them just after. 

Note that my `Quadro600` card has two monitors plugged in.

```bash
Section "Device"
    Identifier     "Videocard0"
    Driver         "nouveau"
    BoardName      "GeForce7600GS"
    BusID          "PCI:4:0:0"
    Screen         2
EndSection

Section "Device"
    Identifier     "Videocard1"
    Driver         "nouveau"
    BoardName      "Quadro600"
    BusID          "PCI:5:0:0"
    Screen	       0 
EndSection

Section "Device"
    Identifier     "Videocard1b"
    Driver         "nouveau"
    BoardName      "Quadro600"
    BusID          "PCI:5:0:0"
    Screen          1
EndSection
```

### The screens

Then write a `screen` section PER monitor to specify the resolution and the graphic card attached.  
If you do not know the resolution choose a low one (`1280x1024`). You will change it later.

Note again that my `Quadro600` card has two monitors plugged in, `Videocard1` and `Videocard1b` are two identifiers for the same device as defined below.
```
Section "Screen"
    Identifier     "Screen0"
    Device         "Videocard1"
    DefaultDepth    24
    SubSection             "Display"
        Depth              16
        Modes              "1680x1050" #Choose the resolution
    EndSubSection
EndSection

Section "Screen"
    Identifier     "Screen1"
    Device         "Videocard1b"
    DefaultDepth    24
    SubSection             "Display"
        Depth              16
        Modes              "1280x1024" #Choose the resolution
    EndSubSection
EndSection

Section "Screen"
    Identifier     "Screen2"
    Device         "Videocard0"
    DefaultDepth    24
    SubSection             "Display"
        Depth              16
        Modes              "1280x1024" #Choose the resolution
    EndSubSection
EndSection
```

### The server layout

Add a `ServerLayout` section at the top of the file.
Here you define the final layout. Set `xinerama` to `on` if you prefer to have one big virtual screen.  
Else choose the central, left and right screens.

```bash
Section "ServerLayout"
    Identifier     "Multihead layout"
    Option      "Xinerama" "off"
    Screen      0  "Screen0" 1280 0 
    Screen      1  "Screen1" RightOf "Screen0" 
    Screen      2  "Screen2" LeftOf "Screen0"
EndSection
```

## Final words

I could not make my 3 screens work properly with i3. A workaround consist on running different i3 instances (actually one per monitor) but this is not satisfactory. 
