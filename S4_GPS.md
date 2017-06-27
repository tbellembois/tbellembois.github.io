# My Galaxy S4 GPS issue

I have a Samsung Galaxy S4 i9505 (jflte) phone.

I have flashed it many times with different custom roms that led to a global GPS failure.  
Google-ing the question, I have discovered that I am not the only one to be affected by this issue.

I have tried the following procedures:

- full wipe with *PhilZ recovery* and *SlimLP* reinstall (I love Slim roms ;))
- full wipe with *PhilZ recovery* and *SlimKat* reinstall
- many “magic” tool that should fix the GPS (GPS Status & Toolbox…)
- flash of a new modem firmware

...with no luck until I decided to reinstall the official Samsung firmware with *Odin* (actually its Linux clone *Heimall*) followed by a new custom rom installation. And that worked !

## step 1: Heimdall/Odin

Install [Heimdall](http://glassechidna.com.au/heimdall/) on Linux (Odin procedure not covered here).

```bash
# debian/ubuntu
aptitude install heimdall-flash
```

For other Linux look at the developer page.

## step 2: Download the firmware

Search/download/unzip your firmware on the [](http://www.sammobile.com/) site.
I have downloaded the file `I9505XXUHOD7_I9505YBTHOD7_DBT.zip`.

```bash
unzip I9505XXUHOD7_I9505YBTHOD7_DBT.zip
tar -xvf I9505XXUHOD7_I9505BTUHOD2_I9505XXUHOD7_HOME.tar
```

You file then have 12 files:

    aboot.mbn
    NON-HLOS.bin
    rpm.mbn
    sbl2.mbn
    sbl3.mbn
    tz.mbn
    boot.img
    recovery.img
    system.img.ext4
    modem.bin
    cache.img.ext4
    hidden.img.ext4

## step 3: Flash the firmware

Turn on your phone in download mode (vol. UP + home + power) and flash it.

```bash
heimdall flash --APNHLOS NON-HLOS.bin --ABOOT aboot.mbn --BOOT boot.img --HIDDEN hidden.img.ext4 --MDM modem.bin --RECOVERY recovery.img --RPM rpm.mbn --SBL2 sbl2.mbn --SBL3 sbl3.mbn --SYSTEM system.img.ext4 --TZ tz.mbn --CACHE cache.img.ext4
```

The phone will automatically reboot once the process is finished. I have not finished the full rom installation process.

## step 4: Install TWRP

[Download](https://dl.twrp.me/jfltexx/)/untar the last version of TWRP.

```bash
tar -xvf twrp-2.8.6.0-jfltexx.tar
```

Turn on your phone in download mode again and flash the `recovery.img` file.

```bash
heimdall flash --RECOVERY recovery.img
```

## step 5: Install the custom rom with TWRP

I have choosen [SlimLP](http://forum.xda-developers.com/showthread.php?t=2556227) alpha that needs to be [rooted](http://forum.xda-developers.com/showthread.php?t=1538053).

## references

- <http://doc.ubuntu-fr.org/heimdall>
- <http://glassechidna.com.au/heimdall/>
- <https://dl.twrp.me/jfltexx/>
- <http://android.stackexchange.com/questions/51065/heimdall-errors-error-partition-recovery-does-not-exist-in-the-specified-pi>
- <http://forum.xda-developers.com/showthread.php?t=2556227>
- <http://forum.xda-developers.com/showthread.php?t=1538053>
- <https://download.chainfire.eu/696/SuperSU/UPDATE-SuperSU-v2.46.zip>
- <http://www.sammobile.com/firmwares/download/44245/I9505XXUHOB7_I9505BTUHOB4_BTU/>
