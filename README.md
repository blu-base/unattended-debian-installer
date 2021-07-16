# Building an Unattended Debian Installation ISO

The Debian Installer which is run during manual installation can be automatized.
This process requires a so-called preseed, which contains answers to the dialogs
which require input.

This repository contains a set of scripts which builds a preseeded ISO image.

Please see the section Common tasks, subsection 'preparing the config'
**before building the image for production**. You need to change the default
passwords.

By default, this builder only creates a semi-automatic installer. The image 
boots into the default bootloader which allows you to select different installer
tasks. To start the automatic installer in this mode you must select 
_Advanced Options_ > _Automatic Installer_.
To make a fully automatic installer, you must run an additional build step,
which is further explained below. The disadvantage of the fully automatic 
installer is that it will override any partitions according to the preseed---
without confirming! That's why it's left to the discretion of the sysadmin using
this builder.

# Features
* Preeseeded installation (semi/fully unattended)
* Atomic partitioning
  * one partition for root, filling the first block device
* Minimal interface during installtion
  * no splash screens
  * only ncurses-based interface
* Add extra files to the installed system
* Post-install script
* headless installed image

# Build system requirements
You need the following packages in order to run the build system for this image:

On Non-Debian-based distributions you need to install `docker(.io)`. A
Debian container is used to build the image in this case.

E.g. openSUSE:

```bash
zypper install docker
```

You'll also need about 2G free space in the build system directory and a
fast internet connection, since there are many packages which need to be
downloaded, up to 1Gb.

On Debian systems, you should use the docker based build system as well.
However, you can skip this build step and use the host system. This is not
recommended, though. But if you want to do it anyway, you'd need to install 
these packages:
* simple-cdd
* xorriso
* build-essential

```bash
apt install xorriso simple-cdd build-essential
```


# Build the image

## Check postinstall script
Make sure your `.postinst` script has executable permissions!
If it does not have executable rights add them via:

```bash
chmod u+x profiles/custom.postinst
```

## Non-Debian host
On non-Debian systems you need to create a docker container (which is Debian) in
order to build the Debian installer image. To create the ISO image run:

```bash
# this will set up a simple Debian container and bring you in
make image

# run the iso building process
make build
```
This will create an iso file `images/debian-10-amd64-CD-1.iso` with the semi-
automatic installer.

To create the fully automatic installer you need to run this additional step:

```bash
# create the fully unattended installer
make build-unattended
```
This will create the file `images/fully-unattended-install.iso`.

The default logins accounts are `root`, `debian`, and `user2`, each with the 
password `insecure`. See in common task how to change these default passwords!

## On Debian host
For a Debian host system, it is optional to create a docker container. However,
if you don't create a container you need to install the aforementioned packages:

```bash
apt install xorriso simple-cdd build-essential
```

Then you can jump straight into:
```bash
# run the iso building process
make build

# create the fully unattended installer
bash buildFullyUnattended.sh
```

Again, you'll find the respective images in the directory `images`.


# Common tasks

## Preparing the config
The setup contains some placeholder settings. This includes **passwords and 
account settings**. These should be replaced before building a production image!

In the `profile/custom.preseed` find these lines:
```
d-i passwd/root-password-crypted password $6$hv7Pc6kN8zVOduf7$qHkYL4Pr8/0ozACoadgt5P3WUZtSfQWw0iYYKzCyY4RGCNgwPzA.9VUyGCJnaWAM3mSRS00aRrIRdP0CdPJOo.

d-i passwd/user-password-crypted password $6$hv7Pc6kN8zVOduf7$qHkYL4Pr8/0ozACoadgt5P3WUZtSfQWw0iYYKzCyY4RGCNgwPzA.9VUyGCJnaWAM3mSRS00aRrIRdP0CdPJOo.
```

### Passwords in preseed
The preseeds for `passwd/root-password-crypted password` and 
`passwd/user-password-crypted password` need to be followed by a hashed 
password. That way plain text passwords are avoided in this build setup. Such 
hashes must be supported by /etc/shadows.

To generate these hashes use the following command:

```
openssl passwd -6 -stdin
```
, then type your password, such as `mypassword`, and press enter. This will 
print out the hash such as:
`$6$hv7Pc6kN8zVOduf7$qHkYL4Pr8/0ozACoadgt5P3WUZtSfQWw0iYYKzCyY4RGCNgwPzA.9VUyGCJnaWAM3mSRS00aRrIRdP0CdPJOo.`.
Leave `openssl` by hitting `CTRL+c`.


### First user in preseed
The preseed also sets the first username and its description, such as:

```
d-i passwd/user-fullname string Debian User
d-i passwd/username     string debian
```

You can replace `Debian User` with a string of your choice. The first username 
in the example is `debian`. Replace `debian` with another label of your choice.
It must conform the user naming conventions for Linux/Debian.

### Additional users via postinstall
In the post install script `profiles/custom.postinst`, you'll find these lines:

```bash
echo "adding user user2"
useradd -g users -m -d /home/user2 -s /bin/bash \
	-p '$6$hv7Pc6kN8zVOduf7$qHkYL4Pr8/0ozACoadgt5P3WUZtSfQWw0iYYKzCyY4RGCNgwPzA.9VUyGCJnaWAM3mSRS00aRrIRdP0CdPJOo.' user2
usermod -a -G sudo user2
```

They create an additional user, `user2`, and add this user to the sudo group 
giving this user root control.

In the `useradd` command the password is again set via a hash (`-p` argument 
followed by the hash string). This default hash corresponds with the password 
`insecure`, again. Therefore, this **hash needs to be changed** for a production
image.

## Adding files to be copied to the installed system
To add files to the install image use the `extras` directory. During the image 
build this directory will be compressed to `extras.tar.gz` and copied onto the 
install image.

In the post install script `profiles/custom.postinst`, the `extras.tar.gz` 
gets copied to `/tmp` and extracted into `/tmp/extras`. From this directory you
can copy files into their destination location. To do this, you have to add 
addtional commands to the post install script.

For example, the archive `extras/myfiles.tar.gz` contains an empty dummy file. 
In the post install script this will be used in the following way:

```bash
mkdir /opt/myscripts

cp /tmp/extras/myfiles.tar.gz /opt/myscripts
cd /opt/myscripts

tar -xzf myfiles.tar.gz
```

It creates a directory in `/opt`, copies the `myfiles.tar.gz` into the new 
directory and extracts it there.

In the same way you can add other files and directories to `extras` and use 
them in the `custom.postinst` script.

## Add packages which shall be installed
Packages can be included into the install image, as well as installed onto the 
target system.
To do both, including and installing, the names of packages need to be added to 
the `profiles/custom.packages` files. The build system will download the 
packages and its dependencies to the install image.

If you only want to add packages to the install image, such as for later 
installation, you can add packages into the `profiles/custom.downloads` 
file.

# References

* [Preseeding](https://wiki.debian.org/DebianInstaller/Preseed)
* [Simple-CDD HowTo](https://wiki.debian.org/Simple-CDD/Howto)
* [Debian Handbook on automated installations](https://debian-handbook.info/browse/squeeze/sect.automated-installation.html)


