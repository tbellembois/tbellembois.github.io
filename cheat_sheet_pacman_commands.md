# pacman cheat sheet

## links

<https://wiki.archlinux.org/index.php/Pacman#Installing_packages>

## search

`-S`:
in local database with `-q`  
in sync database with `-s`  

### search package in db | already installed (by name or description)

```bash
    pacman -Ss string1 string2 ...
    pacman -Qs string1 string2 ...
```

### display information about package in db | already installed


```bash
    pacman -Si package_name
    pacman -Qi package_name
    # two -i display the list of backup files and their modification states
```

### list files installed by a package

```bash
    pacman -Ql package_name
```

### which package a file belongs to

```bash
    pacman -Qo /path/to/file_name
```

### orphans packages | explicitly installed

```bash
    pacman -Qdt
    pacman -Qet
```

## install | with regex | specific version

```bash
    pacman -S package_name1 package_name2 ...
    pacman -S $(pacman -Ssq package_regex)
    pacman -S extra/package_name
```

## remove | with dependencies | with dependant parents

`-n` to remove configuration files

```bash
    pacman -R package_name
    pacman -Rs package_name
    pacman -Rsc package_name
```

## upgrade

```bash
    pacman -Syu
    yaourt -Syu --aur
```
