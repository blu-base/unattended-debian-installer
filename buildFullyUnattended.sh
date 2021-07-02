#!/bin/bash

SOURCENAME="debian-10-amd64-CD-1"
ISONAME="fully-unattended-install"

# check if there is an image already built.
if [[ ! -e images/$SOURCENAME.iso ]] ; then
  echo "Source is missing (images/$SOURCENAME.iso)"
  echo 'Please run `make build` before running this script'
  exit 1
fi

################################################################################
echo "Making the fully-automatic install bootloader"

# extract the image
echo "extracting the image..."
xorriso -osirrox on -indev images/$SOURCENAME.iso \
  -extract / images/isofiles/

# modify the ISO image bootloader
echo "modifying the bootloaders..."

sed -i '/^default vesamenu.c32.*/d' images/isofiles/isolinux/isolinux.cfg

echo "set timeout_style=hidden" >> images/isofiles/boot/grub/grub.cfg
echo "set timeout=0" >> images/isofiles/boot/grub/grub.cfg
echo "set default=1" >> images/isofiles/boot/grub/grub.cfg

#
echo "recreate md5sums for ISO image"
cd images/isofiles
chmod a+w md5sum.txt
md5sum $(find -follow -type f) > md5sum.txt
chmod a-w md5sum.txt

#
echo "generate final iso: \nimages/$ISONAME.iso"
cd ..
chmod a+w isofiles/isolinux/isolinux.bin
xorrisofs -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table -o $ISONAME.iso isofiles





