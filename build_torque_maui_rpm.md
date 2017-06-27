# Building Torque/MAUI RPM on SL6

Procedure used with the `3.0.4` versions of Torque and `3.3.1` of MAUI on `SL6`.

## References

<http://www.adaptivecomputing.com/products/open-source/torque/torque-archived-versions-library/>  
<http://stackoverflow.com/questions/21559477/how-to-pass-user-defined-parameters-to-rpmbuild-to-fill-variables>  
<http://unix.stackexchange.com/questions/125609/install-latest-gcc-on-rhel-6-x86-64>  
<http://blog.ajdecon.org/installing-the-maui-scheduler-with-torque-410/>  

## Torque

### Getting the source code

Go to <http://www.adaptivecomputing.com/products/open-source/torque/torque-archived-versions-library/> to download the `3.0.4` version.

### Prerequisites

Install the `devtoolset-2` and `rpm-build` packages to compile and build the RPMs.

```bash
    wget -O /etc/yum.repos.d/slc6-devtoolset.repo     http://linuxsoft.cern.ch/cern/devtoolset/slc6-devtoolset.repo
    yum install devtoolset-2
    yum install rpm-build
```

### Building the Torque RPMs.

```bash
    rpmbuild -tb --define '_prefix /opt/torque-3.0.4' --define '_with-rcp rcp --enable-clients'  torque-3.0.4.tar.gz
```

RPMs are generated in `/root/rpmbuild/`.  

We can pass the compilation options with `--define '_variable _value'`. To see the possible options, untar the `torque-3.0.4.tar.gz` file and edit the `torque.spec` file. Variables are named like `%{_variable}`.  

For example the file defines `%{_prefix}` to pass `--define '_prefix /opt/torque-3.0.4'` as an option to `rpmbuild`. Note that you have to remove `%{}`.  

## MAUI

### Getting the source code

Go to <http://www.adaptivecomputing.com/wpfb-file/maui-3-3-1-tar-gz-2/> to download the version `3.3.1`.

### Torque installation

You need to install Torque to build the MAUI RPM..

```bash
    yum localinstall /root/rpmbuild/RPMS/x86_64/torque-*.rpm
```

### MAUI compilation

```bash
    tar zxvf maui-3.3.1.tar.gz
    cd maui-3.3.1
    ./configure --prefix=/opt/maui-3.3.1 --with-pbs=/opt/torque-3.0.4
    make
```

### Building the RPM with fpm

#### fpm installation

```bash
    yum install rubygems ruby-devel
    gem install fpm
```

#### MAUI Makefile modification for fpm

`fpm` can build an RPM package from a `makefile` defining the target `make install DESTDIR=/path/to/install`.  

We have to adapt the MAUI `makefile` with:
```bash
    sed -i'.bkp' 's/\$(INST_DIR)/\$(DESTDIR)\/\$(INST_DIR)/g' src/*/Makefile
    sed -i'' 's/\$(MSCHED_HOME)/\$(DESTDIR)\/\$(MSCHED_HOME)/g' src/*/Makefile
```

#### Preparing the fpm resources

Installing MAUI in a temporary directory:
```bash
    DESTDIR=/tmp/maui make install
```

Setting up the initialisation scripts:
```bash
    mkdir /tmp/maui/usr
    mkdir /tmp/maui/etc
    mkdir /tmp/maui/etc/profile.d
    mkdir /tmp/maui/etc/init.d
    cp etc/maui.d /tmp/maui/etc/init.d/
    cp etc/maui.{csh,sh} /tmp/maui/etc/profile.d/
```

Then edit the `/tmp/maui/etc/init.d/maui.d` file to set the variable `MAUI_PREFIX=/opt/maui-3.3.1`.

Create a file `/tmp/maui/post-install.sh` with:

    #!/bin/bash
    chkconfig --add maiu.d
    chkconfig --level 3456 maui.d on

Create a file `/tmp/maui/pre-uninstall.sh` with:

    #!/bin/bash
    chkconfig --del maui.d

#### Building the RPM

```bash
    fpm -s dir -t rpm -n maui -v 3.3.1 -C /tmp/maui \
-p /tmp/maui-3.3.1-x86_64-fpmbuild.rpm --post-install /tmp/maui/post-install.sh \
--pre-uninstall /tmp/maui/pre-uninstall.sh etc usr opt
```

The package is created in `/tmp/maui-3.3.1-x86_64-fpmbuild.rpm`.

#### Checking the RPM

```bash
    rpm -q --filesbypkg -p /tmp/maui-3.3.1-x86_64-fpmbuild.rpm
```
