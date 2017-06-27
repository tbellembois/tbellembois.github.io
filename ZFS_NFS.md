# NFS exports of ZFS volumes

Setting up NFS V4 exports from ZFS filesystems with ACL can be a little bit tricky.

Here is what I have done.

My ZFS volumes are:

```bash
# zfs list
datapool                            20.3T   157T  44.8K  /datapool
datapool/IGFL                       20.3T  89.7T  54.8K  /data/IGFL
datapool/IGFL/backup                3.95G  89.7T  3.95G  /data/IGFL/backup
datapool/IGFL/galaxy                1.30T  89.7T  1.30T  /data/IGFL/galaxy
datapool/IGFL/perso                  234G  89.7T   231G  /data/IGFL/perso
datapool/IGFL/projects              1.38G   499G  1.38G  /data/IGFL/projects
datapool/IGFL/teams                 18.8T  89.7T  1.76M  /data/IGFL/teams
datapool/IGFL/teams/igfl_averof      562G  2.45T   562G  /data/IGFL/teams/igfl_averof
datapool/IGFL/teams/igfl_bleicher   8.93G  2.99T  8.93G  /data/IGFL/teams/igfl_bleicher
...
```

I use ACL on each directory:

```bash	
# getfacl /data/IGFL/teams/igfl_averof
# file: data/IGFL/teams/igfl_averof
# owner: root
# group: root
# flags: sst
user::rwx
group::---
group:acces_igfl_team_averof:rwx
mask::rwx
other::---
default:user::rwx
default:group::---
default:group:acces_igfl_team_averof:rwx
default:mask::rwx
default:other::---
```

## create an NFS root to export volumes

create the directory:

```bash
mkdir /nfs-export
```

`bind` each folder you want to export in this directory:

```bash
mkdir /nfs-export/igfl_averof
mount  --bind /data/IGFL/teams/igfl_averof /nfs-export/igfl_averof
```

or edit the `/etc/fstab` file to make the changes permanent:

    ...
    /data/IGFL/teams/igfl_averof  /nfs-export/igfl_averof  none bind

## NFS server export configuration

edit the `/etc/exports` file:

    # IMPORTANT, define the root of the NFS tree
    # we add the fsid=0 option
    # this directory will not be mounted by the clients  but it is a requirement
    /nfs-export 140.77.82.0/24(fsid=0,rw,no_subtree_check,sync)

    # then each directory we want to export
    # the nohide option will make this directory visible even if the client does not mount the /nfs-export root directory
    /nfs-export/igfl_averof 140.77.82.224(nohide,rw,no_subtree_check,sync)
    /nfs-export/igfl_laudet 140.77.82.224(nohide,rw,no_subtree_check,sync)
    ...

## NFS client configuration

on the server `140.77.82.224`, edit the `/etc/fstab` file:

    ...
    140.77.82.229:/igfl_averof /data/teams/igfl_averof nfs4 defaults,auto,noatime,intr 0 0
    140.77.82.229:/igfl_laudet /data/teams/igfl_averof nfs4 defaults,auto,noatime,intr 0 0


1. specify ''nfs4'' as a protocole
2. no need to mount the `/nfs-export` directory, even if it is exported by the server
3. we do not specify the full path, ie `/nfs-export/igfl_averof`, but the path from the NFS root directory, ie `/igfl_averof`

## Note

You (apparently) can not export a classic subdirectory of a ZFS volume.

For example on my `/data/IGFL/galaxy` directory (which is a ZFS volume) I have 2 subdirectories `upload` and `files`. I have had `permission denied` errors trying to export theses directories directly. I have exported the `/data/IGFL/galaxy` to solve the problem.

## References

- [http://zfsguru.com/forum/zfsgurudevelopment/516](http://zfsguru.com/forum/zfsgurudevelopment/516)

