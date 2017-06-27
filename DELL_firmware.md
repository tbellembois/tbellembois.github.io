# Recover a Dell laptop BIOS flash issue

I have tried to update a Dell latitude D630 BIOS. The flash process went wrong and my laptop was not able to boot anymore (black screen at startup).
I thought that my computer was dead but I have finally found a solution mixing different informations from the Internet (sorry I have not saved the links).

`<note>`
Most laptops have an "ultimate" rescue mode to recover from BIOS flash problems. This procedure should work with Dell laptops but other manufacturers have probably implemented such a method.
The generic method consists on:

*  downloading the firmware to flash

*  extracting a ''.something'' file from the dowloaded file

*  create a bootable USB key and copy the ''.something'' file

*  use a magic key combination to boot the laptop in a special BIOS flash mode
`</note>`

## Download the firmware file

Go to the [Dell](http://www.dell.com/) website and download the ''.exe'' file for your laptop.

## Extract the firmware file

Use a windows machine (sorry for that... really...), open a command line:

	
	cd /path/to/my/exe
	D630_A19.exe -writehdr


This will generate a ''.hdr'' file.

## Create a freedos USB key

Download [freedos](http://www.freedos.org/) and create a bootable USB key from it. Then copy the ''.hdr'' file on the USB key.

## Rescue your laptop

 1.  shutdown your ill laptop, remove the battery and the power supply
 2.  plug your USB key in
 3.  hold the ''end'' key and plug your power supply
 4.  when the battery icon will become orange, release the ''end'' key
 5.  your laptop should work for some seconds (reflashing the bios) and automatically reboot
 6.  reconfigure the bios


