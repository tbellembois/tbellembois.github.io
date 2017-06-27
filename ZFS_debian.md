# ZFS installation on Debian

## Packages installation

```bash
su -
wget http://archive.zfsonlinux.org/debian/pool/main/z/zfsonlinux/zfsonlinux_2%7Ewheezy_all.deb
dpkg -i zfsonlinux_2~wheezy_all.deb
apt-get update
apt-get install debian-zfs
```

## Hardware

A `Dell R720` connected to a `60 * 4TB` disk device.
The system is installed on `/dev/sda`.

```bash
fdisk -l /dev/sda
	   Device Boot      Start         End      Blocks   Id  System
	/dev/sda1            2048    15624191     7811072   82  Linux swap / Solaris
	/dev/sda2   *    15624192   285472767   134924288   83  Linux
	
ls /dev/sd*
	/dev/sda   /dev/sdaf  /dev/sdan  /dev/sdav  /dev/sdbc  /dev/sdd  /dev/sdl  /dev/sdt
	/dev/sda1  /dev/sdag  /dev/sdao  /dev/sdaw  /dev/sdbd  /dev/sde  /dev/sdm  /dev/sdu
	/dev/sda2  /dev/sdah  /dev/sdap  /dev/sdax  /dev/sdbe  /dev/sdf  /dev/sdn  /dev/sdv
	/dev/sdaa  /dev/sdai  /dev/sdaq  /dev/sday  /dev/sdbf  /dev/sdg  /dev/sdo  /dev/sdw
	/dev/sdab  /dev/sdaj  /dev/sdar  /dev/sdaz  /dev/sdbg  /dev/sdh  /dev/sdp  /dev/sdx
	/dev/sdac  /dev/sdak  /dev/sdas  /dev/sdb   /dev/sdbh  /dev/sdi  /dev/sdq  /dev/sdy
	/dev/sdad  /dev/sdal  /dev/sdat  /dev/sdba  /dev/sdbi  /dev/sdj  /dev/sdr  /dev/sdz
	/dev/sdae  /dev/sdam  /dev/sdau  /dev/sdbb  /dev/sdc   /dev/sdk  /dev/sds
```

## Organize disks 

Edit `/etc/zfs/vdev_id.conf` and define aliases for disk devices found in `/dev/disk/by-id/`.

The following command gives the disk ids sorted by device name:

```bash
ls -la /dev/disk/by-id/ | grep scsi | awk '{print $11, $9}' | sort
	../../sda scsi-36c81f660cf6ad0001a7a9b5b10cd9dff
	../../sda1 scsi-36c81f660cf6ad0001a7a9b5b10cd9dff-part1
	../../sda2 scsi-36c81f660cf6ad0001a7a9b5b10cd9dff-part2
	../../sdaa scsi-35000c500579cd357
	../../sdab scsi-35000c500579e30af
	...
```

Pre-fill the `/etc/zfs/vdev_id.conf` with:

```bash
ls -la /dev/disk/by-id/ | grep scsi | awk '{print $11, $9}' | sort | awk '{pr
	int $2}' > /etc/zfs/vdev_id.conf
```

and then edit it to define aliases (I add to remove the first 3 lines corresponding to the `sda` disk and its 2 partitions):
	
	alias log0 pci-0000:03:00.0-scsi-0:0:0:0                       
	alias log1 pci-0000:03:00.0-scsi-0:0:1:0
	alias cache0 pci-0000:03:00.0-scsi-0:0:2:0
	alias cache1 pci-0000:03:00.0-scsi-0:0:3:0
	alias cache2 pci-0000:03:00.0-scsi-0:0:4:0
	alias cache3 pci-0000:03:00.0-scsi-0:0:5:0
	alias d0 scsi-35000c500579cd357
	alias d1 scsi-35000c500579e30af
	alias d2 scsi-35000c500579cb8e7
	alias d3 scsi-35000c500579cc13b
	alias d4 scsi-35000c500579cb8f7
	...

```bash
udevadm trigger --action=create /etc/zfs/vdev_id.conf
```

## Create the pool 

I want a RaidZ pool with ZIL, mirrored cache and NO disk spare.

```bash
zpool create datapool \
	raidz d0 d1 d2 d3 d4 d5 \
	raidz d6 d7 d8 d9 d10 d11 \
	raidz d12 d13 d14 d15 d16 d17 \
	raidz d18 d19 d20 d21 d22 d23 \
	raidz d24 d25 d26 d27 d28 d29 \
	raidz d30 d31 d32 d33 d34 d35 \
	raidz d36 d37 d38 d39 d40 d41 \
	raidz d42 d43 d44 d45 d46 d47 \
	raidz d48 d49 d50 d51 d52 d53 \
	raidz d54 d55 d56 d57 d58 d59 \
	log mirror log0 log1 \
	cache cache0 cache1 cache2 cache3 \
```

## Create the ZFS volumes 

```bash	
zfs create datapool/IGFL
zfs set mountpoint=/data/IGFL datapool/IGFL
zfs set compression=on datapool/IGFL
zfs set acltype=posixacl datapool/IGFL
zfs set xattr=sa datapool/IGFL
zfs set aclinherit=passthrough datapool/IGFL
zfs set atime=off datapool/IGFL
zfs set snapdir=hidden datapool/IGFL
zfs set quota=110T datapool/IGFL
zfs set refquota=90T datapool/IGFL
```

## Some usefull commands

Detect disks not defined in `vdev_id.conf`:

```bash	
for device in $(ls -la /dev/disk/by-path/ | grep pci | grep -v "part" | awk '{print $9}'); do echo "$device";grep "$device" /etc/zfs/vdev_id.conf ; done;
	
	pci-0000:00:1f.2-scsi-0:0:0:0 -> not defined
	pci-0000:03:00.0-scsi-0:2:0:0 -> not defined but system disk /dev/disk/by-path/pci-0000:03:00.0-scsi-0:2:0:0 -> ../../sda
	pci-0000:07:00.0-scsi-0:2:0:0
	alias d1 /dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:0:0
	pci-0000:07:00.0-scsi-0:2:1:0
	alias d2 /dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:1:0
	pci-0000:07:00.0-scsi-0:2:10:0
	...
```

Detect disks defined in `vdev_id.conf` but not present.

```bash
while read line; do ls $(echo $line | awk '{ print $3}') ; done < /etc/zfs/vdev_id.conf
	
	/dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:14:0
	/dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:16:0
	/dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:18:0
	/dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:19:0 -> ah ah !
	ls: impossible d'accéder à /dev/disk/by-path/pci-0000:07:00.0-scsi-0:2:21:0: No such file or directory 
```

## References

- [http://zfsonlinux.org/debian.html](http://zfsonlinux.org/debian.html)
- [http://www.axllent.org/docs/view/erase-your-mbr/](http://www.axllent.org/docs/view/erase-your-mbr/)
- [https://pthree.org/2012/04/17/install-zfs-on-debian-gnulinux/](https///pthree.org/2012/04/17/install-zfs-on-debian-gnulinux/)
- [http://bernaerts.dyndns.org/linux/75-debian/279-debian-wheezy-zfs-raidz-pool](http://bernaerts.dyndns.org/linux/75-debian/279-debian-wheezy-zfs-raidz-pool)
- [http://www.pouwiel.com/?p=2098](http://www.pouwiel.com/?p=2098)

