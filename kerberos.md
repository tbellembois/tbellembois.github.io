# NFS4/Kerberos/Active Directory - the last crusade

## Introduction

After fighting for 3 weeks trying to setup a NFS/Kerberos configuration with an ActiveDirectory, and Googling thousands of mailing lists and tutorials, here is my succesfull story.  
Hope it may help others...

## Configuration

The KDC is a Windows AD. The NFS server and clients are under Linux.

- AD: `Windows Server 2016`
- Linux: `Debian Stretch`
- Linux packages: `sssd libpam-sss libnss-sss krb5-user`
- Domain: `iut.local`
- AD server name: `coruscant` is also the DNS
- NFS server name: `dublin`
- NFS client name: `z-stretchl`

> Ensure that `packagekit` is installed (it should be in a default Gnome installation) and that the `rpcsec_gss_krb5` kernel module is loaded (`lsmod | grep rpcsec_gss_krb5` should return something).

## step 1: linux configuration

I have tried to use the `realm` command to join my domain from both the client and NFS server.

```bash
    root@z-stretchl:~# realm join -U administrateur
```

The command was successfull and the machine appeared on my AD but I could not retrieve my users with `getent`. I tried another approch.

### configure the hosts file (client and server)

It is important that the first line contains the IP addresses and fqdn's of the machines. Moreover the machines fqdn must be registered in the DNS.

```bash
192.168.128.34  dublin.iut.local dublin
127.0.0.1       localhost.localdomain localhost
```
```bash
192.168.105.225 z-stretchl.iut.local z-stretchl
127.0.0.1       localhost.localdomain localhost
```

```bash
root@z-stretchl:~# nslookup z-stretchl
Server:         192.168.105.5
Address:        192.168.105.5#53

Name:   z-stretchl.iut.local
Address: 192.168.105.225

root@z-stretchl:~# nslookup dublin
Server:         192.168.105.5
Address:        192.168.105.5#53

Name:   dublin.iut.local
Address: 192.168.128.34
```

### configure krb5.conf (client and server)

```
[libdefaults]                                                       
        default_realm = IUT.LOCAL
        kdc_timesync = 1            
        ccache_type = 4         
        forwardable = true            
        proxiable = true                                                            
[realms]                              
    IUT.LOCAL = {
        kdc = coruscant                                                           
    }
[domain_realm]
    .iut.local = IUT.LOCAL
    iut.local = IUT.LOCAL
```

Do NOT put `allow_weak_crypto = true` in the `libdefaults` section. This is not needed anymore.

### configure sssd.conf (client and server)

```
[sssd]
domains = iut.local
services = nss, pam
config_file_version = 2

[nss]
filter_groups = root
filter_users = root
default_shell = /bin/bash

[pam]
reconnection_retries = 3

[domain/iut.local]
krb5_validate = True
krb5_realm = IUT.LOCAL
subdomain_homedir = %o
default_shell = /bin/bash
cache_credentials = True
id_provider = ad
access_provider = ad
chpass_provider = ad
auth_provide = ad
ldap_schema = ad
ad_server = coruscant
ad_hostname = z-stretchl.iut.local
ad_domain = iut.local
ad_gpo_access_control = permissive
use_fully_qualified_names = False
ad_enable_gc = False
```

- the `subdomain_homedir = %o` parameter is needed to retrieve the `unixHomeDirectory` of the logged user from the AD
- the `ad_enable_gc = False` prevents sssd to loose the `unixHomeDirectory` user parameter while reloading its cache

![unixhomedir][unixhomedir]

- the `default_shell` can be configured as needed
- the `ad_gpo_access_control = permissive` appears to be needed to avoid GPO-like permissions issues
- note that the parameters are case sensitive especially the `krb5_realm` that is commonly the uppercase version of the domain

## configure idmapd.conf (client and server)

```
[General]

Verbosity = 0
Pipefs-Directory = /run/rpc_pipefs
Domain = iut.local 

[Mapping]

Nobody-User = nobody
Nobody-Group = nogroup

```

- the `Domain` should be filled


## configure nfs-common (client and server)

```
...
NEED_STATD=yes
NEED_IDMAPD=yes
NEED_GSSD=yes
...
```

- parameters needed to enable kerberos authentication
- without `NEED_STATD` on the server side we encountered `kernel: lockd: cannot monitor` errors and slowness on clients

## configure nfs-kernel-server (server)

```
...
RPCMOUNTDOPTS="--manage-gids"
NEED_SVCGSSD="yes"
...
```

- parameters needed to enable kerberos authentication

# step 2: AD configuration and keytab generation

This was the longest taks. I have generated thousands of keytab and googled the entire www to find the matching configuration.

## general principle

You have to create an **AD user** per machine (NFS server and clients). The name of these users is not important. 
The you must create **principals** bound to the previous users. A principal is a kerberos element used to authenticate machines, users and services.
Finally you have to create **keytabs** files for the Linux clients. 

## create an AD user per machine

You can do it with the GUI tools or using the `dsadd` command line tool.
Operations must my performed with the administrator account.

![dsadd][dsadd]

server:
```bash
dsadd user CN=nfs-dublin,CN=Users,DC=iut,DC=local -samid nfs-dublin -pwd 1234
```
client:
```bash
dsadd user CN=nfs-z-stretchl,CN=Users,DC=iut,DC=local -samid nfs-z-stretchl -pwd 5678
```

- the `samid` attribute name is free
- choose a secure password

## create kerberos principals bound to the AD users

### What I have understund (but I may be wrong).  

You have to create a `host` principal to authenticate the machine on the AD (for sssd).
You have to create a `service` principal to authenticate the machine on the nfs server. With this principal the machine will be able to mount the krb5 NFS exported paths but this principal is not enought to access the path (ie. read/write).

```bash
    root@z-stretchl:~# mount -t nfs4 -o sec=krb5 dublin.iut.local:/home/prof /tmp/test/
    root@z-stretchl:~# touch /tmp/test/toto
    touch: impossible de faire un touch '/tmp/test/toto': Permission non accordée
```
Ok, the permission denied is expected.

To be able to access the exported path you first have to get a TGT (ticket granting ticket) from the AD with a registered user with the `kinit` command. This ticket is like an ID card that proves that you are the person your pretend you are.

```bash
    root@z-stretchl:~# kinit thbellem
    Password for thbellem@IUT.LOCAL: 
```
If the authentication is succesfull you can display your TGT with `klist`.
```bash
    root@z-stretchl:~# klist
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: thbellem@IUT.LOCAL

Valid starting       Expires              Service principal
28/03/2018 13:55:06  28/03/2018 23:55:06  krbtgt/IUT.LOCAL@IUT.LOCAL
        renew until 29/03/2018 13:54:57
```
The ticket is valid for 10 hours.

With this TGT you will be able to get a service ticket for the NFS server and then access the mounted filesystem (this is automatically done trying to access the mounted filesystem).

```bash
root@z-stretchl:~# touch /tmp/test/thbellem/toto
touch: impossible de faire un touch '/tmp/test/thbellem/toto': Permission non accordée
```

Still permission denied ? Yes even with a TGT the root user is squashed. I have a correct TGT but the path I tried to access is owned by uid/gid of user thbellem and of course NFS does not allow me to access this path.


But if you log with a common user with th `login` command (that automatically get a TGT from the AD):

```bash
root@z-stretchl:~# login thbellem
thbellem@z-stretchl:/$ klist 
Ticket cache: FILE:/tmp/krb5cc_1467053722_69OWsi
Default principal: thbellem@IUT.LOCAL

Valid starting       Expires              Service principal
28/03/2018 14:05:51  29/03/2018 00:05:51  krbtgt/IUT.LOCAL@IUT.LOCAL
        renew until 29/03/2018 14:05:51

thbellem@z-stretchl:/$ touch /tmp/test/thbellem/toto
thbellem@z-stretchl:/$ 
```

Success ! Of course the remote `thbellem` directory is owned by the user `thbellem`.

### creating the principal names for the users

server:
```bash
setspn -A host/dublin nfs-dublin
setspn -A host/dublin.iut.local nfs-dublin
setspn -A host/dublin.iut.local@IUT.LOCAL nfs-dublin
setspn -A nfs/dublin nfs-dublin
setspn -A nfs/dublin.iut.local nfs-dublin
setspn -A nfs/dublin.iut.local@IUT.LOCAL nfs-dublin
```

client:
```bash
setspn -A host/z-stretchl nfs-z-stretchl
setspn -A host/z-stretchl.iut.local nfs-z-stretchl
setspn -A host/z-stretchl.iut.local@IUT.LOCAL nfs-z-stretchl
setspn -A nfs/z-stretchl nfs-z-stretchl
setspn -A nfs/z-stretchl.iut.local nfs-z-stretchl
setspn -A nfs/z-stretchl.iut.local@IUT.LOCAL nfs-z-stretchl
```

The `host` principals are the machines principals used to join the AD to authenticate the users. The `nfs` principals are the machines principals used to authenticate the machine on the NFS server to mount the exported filesystem. 

The 3 principal names:
- hostname
- hostname.domain
- hostname.domain@REALM
are required for each user.

### creating the keytabs

```
    ktpass -princ nfs/dublin.iut.local@IUT.LOCAL -pass 1234 -mapuser IUT\nfs-dublin -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$user.keytab -crypto rc4-hmac-nt
    ktpass -princ nfs/z-stretchl.iut.local@IUT.LOCAL -pass 1234 -mapuser IUT\nfs-z-stretchl -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\$user.keytab -crypto rc4-hmac-nt
``` 
- enter the same password as the user password

For the `-crypto` parameter I have entered the first returned by the klist command.

![klistwin][klistwin]

## Usefull debug commands

```bash
 rpcdebug -m nfsd -s all
 rpcdebug -m rpc -s all
 rpc-gssd -vvv -f
```

## Links

- <https://www.safesquid.com/content-filtering/integrating-linux-host-windows-ad-kerberos-sso-authentication#h.wz9jygqxw6vc>  
- <https://support.hpe.com/hpsc/doc/public/display?docId=emr_na-c01096258>  
- <https://social.technet.microsoft.com/Forums/fr-FR/0680dcee-9153-43ba-a4b0-a754a5f0db33/kinit-client-not-found-in-kerberos-database-while-getting-initial-credentials?forum=winservergen>
- <https://ovalousek.wordpress.com/2015/10/15/enable-kerberized-nfs-with-sssd-and-active-directory/>
- <https://help.ubuntu.com/community/NFSv4Howto#NFSv4_and_Autofs>
- <https://groups.google.com/forum/#!topic/linux.samba/uP119bAe0CA>
- <https://blogs.nologin.es/rickyepoderi/index.php?/archives/104-Two-Tips-about-Kerberos.html>
- <http://coewww.rutgers.edu/www1/linuxclass2009/doc/krbnfs_howto_v3.pdf>


## Plus: samba and SSSD

To enable SSSD/kerberos authentication with samba add the following principal names:
```bash
    setspn -A host/dublin nfs-dublin
    setspn -A host/dublin.iut.local nfs-dublin
    setspn -A host/dublin.iut.local@IUT.LOCAL nfs-dublin
    setspn -A nfs/dublin nfs-dublin
    setspn -A nfs/dublin.iut.local nfs-dublin
    setspn -A nfs/dublin.iut.local@IUT.LOCAL nfs-dublin
    setspn -A cifs/dublin nfs-dublin
    setspn -A cifs/dublin.iut.local nfs-dublin
    setspn -A cifs/dublin.iut.local@IUT.LOCAL nfs-dublin
    setspn -A cifs/dublin@IUT.LOCAL nfs-dublin
```
and generate an additionnal keytab:
```bash
	ktpass -princ nfs/dublin.iut.local@IUT.LOCAL -pass 1234 -mapuser IUT\nfs-dublin -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\nfs-dublin.keytab -crypto rc4-hmac-nt
	ktpass -princ cifs/dublin@IUT.LOCAL -pass 1234 -mapuser IUT\nfs-dublin -pType KRB5_NT_PRINCIPAL -out c:\TMP\krb\cifs-dublin.keytab -crypto rc4-hmac-nt
```

Rsync the keytabs on the server and merge them with:
```bash
    ktutil
    read_kt /tmp/nfs-dublin.keytab
    read_kt /tmp/cifs-dublin.keytab
    write_kt /etc/krb5.keytab
```

Here is the part of the relevant `/etc/smb.conf` configuration:
```
server role = member server
security = ads
workgroup = IUT
realm = iut.local
kerberos method = system keytab
```

[unixhomedir]: /media/kerberos/unixhomedir.png
[dsadd]: /media/kerberos/dsadd.png
[klistwin]: /media/kerberos/klistwin.png