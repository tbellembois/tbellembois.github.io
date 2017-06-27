# Linux commands

## data transfert

### optimized rsync

```bash
rsync -av --numeric-ids -W --inplace --rsh="ssh -c blowfish" source/ destination/
```

### zfs send and receiver with mbuffer

on the receiver

```bash
mbuffer -s 128k -m 1G -I 9090 | zfs receive mypool/data
```

on the sender
	
```bash
zfs send myotherpool/data@snapshot-20140701020101 | mbuffer -s 128k -m 1G -O server:9090
```

### nc, tar with mbuffer

on the receiver

```bash
nc -q 1 -l -p 7000 | mbuffer -s 128k -m 1G | tar xv
```

on the sender

```bash
tar cf - mydirectory/ | mbuffer -s 128k -m 1G | nc -q 1 server.foo.fr 7000
```

* -s: lowest common multiple of the native block size
* -m: total buffer size

###  dd a partition and transfert it via ssh

```bash
dd if=/dev/mmcblk0 | ssh user@backup.server "gzip -9 > sdcard.gz"
```

###  restore a partition with a dd file via ssh

```bash
zcat sdcard.gz | ssh root@freerunner.address dd of=/dev/mmcblk0
```

## ssh

forward 8080 local port to 8080 target-machine port

```bash
ssh -L8080:localhost:8080 user@target-machine
```

forward 8080 local port to 8080 target-machine port using a proxy machine

```bash
ssh -L8080:target-machine:8080 proxy-machine
```

run a command with a different user

```bash
su -m $USER -c "commande.sh"
```

## aptitude

###  aptitude add key

```bash
gpg --keyserver pgpkeys.mit.edu --recv-key  010908312D230C5F
gpg -a --export 010908312D230C5F | sudo apt-key add -
```

###  aptitude expired

```bash
aptitude -o Acquire::Check-Valid-Until=false update
```

## file manipulation

### du sort directory by size

```bash
du -hxBG --max-depth=1 share/ | sort -n
```

`G` means gigabyte

### find + mv

```bash
# append ".table" to the files with no extension
for file in $(find . ! -iname "*.table"); do mv $file $file.table; done;
```

###  convert a file from ISO-8859-1 into UTF-8

```bash
iconv --from-code=ISO-8859-1 --to-code=UTF-8 ./oldfile.htm > ./newfile.html
```

###  create a multi volume archive with tar

```bash
tar cvp --total --file /tmp/arch1.tar --file /tmp/arch2.tar --multi-volume --tape-length 4812800 ./
```

`tape-length`: number of megabytes * 1024 - here 4.7GB = 4.7 * 1000 * 1024 (actually we should do 4.7 * 1024 * 1024)

###  extract a multi volume archive created with tar

```bash
tar xv --total --file ~/arch1.tar --file ~/arch2.tar --multi-volume
```

## iptables

###  forward a port with iptables

```bash
iptables -t nat -A PREROUTING -p tcp -d 127.0.0.1 --dport 3306 -j DNAT --to-destination 140.77.XX.YYY:3316
```

## LDAP

###  perform an LDAP search

```bash
ldapsearch -x -b "ou=people,dc=mycompany,dc=fr" -H ldap://ldap.mycompany "employeeType=SA"
```

## databases

### MySQL dump

```bash
mysqldump dbname -hlocalhost -uuser -ppassword > file.sql
```

### MySQL restore

```bash
mysql -uuser -ppassword -hlocalhost dbname --default_character_set utf8 < script.sql
```

### MySQL grant privileges

```bash
GRANT ALL PRIVILEGES ON *.* TO 'user'@'localhost' IDENTIFIED BY 'user';
```

### MySQL socket connection

```bash
mysql -S /var/run/mysqld6/mysqld6.sock -u root -p -d dbname
```

### PostgreSQL restore

```bash
su - postgres
psql -p 5442
postgres$ \i /var/backups/postgresql/dumpall-5442.sql.20110307040007
```

## Java

Java compilation

```bash
javac -classpath ./commons-logging.jar:./ net/sf/jpam/Pam.java
```

Class paths to the `.jar`, `.zip` or `.class` files.  
Each classpath should end with a filename or directory depending on what you are setting the class path to:

*  For a `.jar` or `.zip` file that contains `.class files`, the class path ends with the name of the `.zip` or `.jar` files.
*  For `.class` files in an unnamed package, the class path ends with the directory that contains the `.class` files. For `.class` files in a named package, the class path ends with the directory that contains the "root" package (the first package in the full package name).

## other

### find and restore with full path (from a .zfs snapshot)

```bash
cd /data/IGFL/teams/laudet/.zfs/snapshot/20150324-00-01/Coraline
for file in $(find . -iname htseq*.count); do lastpart=$(dirname ${file:1}); fullpart="/data/IGFL/teams/laudet/Coraline"$lastpart"/"; echo "rsync de $file > $fullpart"; rsync -avz $file $fullpart; done;
```

### really geek mass rename command

```bash
for thefile in $(ls *.table); do export thefile; table_name=$(python -c 'import os; import re; match = re.match("^[a-z0-9]+_(?P`<tablename>`[A-Z_]+)\.table$", os.environ["thefile"]); print match.group("tablename") if match else None;'); if [[ $table_name != "None" ]]; then echo "$thefile -> f39c96fb0386e99b2f29452eadbfee99_$table_name"; cp $thefile f39c96fb0386e99b2f29452eadbfee99_$table_name  ; fi; done;
```

### watch a backuppc backup progress

On the client:

```bash
watch "lsof -n | grep rsync | egrep ' (REG|DIR) ' | egrep -v '( (mem|txt|cwd|rtd) |/LOG)' | awk '{print $9}'"
```

reference: [http://sysadminnotebook.blogspot.fr/2011/09/watch-backuppc-progress.html](http://sysadminnotebook.blogspot.fr/2011/09/watch-backuppc-progress.html)


