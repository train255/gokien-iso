#!/bin/bash

# load config
source etc/congrego.conf

# check for dependencies
dependency_list='live-build livecd-rootfs syslinux-themes-elementary gfxboot-theme-ubuntu dpkg-dev syslinux'
for package in $dependency_list; do
dpkg -L "$package" >/dev/null 2>&1 || missing_dependencies="$missing_dependencies $package"
done

if [ "$missing_dependencies" != "" ]; then
echo "Missing dependencies! Please install the following packages:
$missing_dependencies" > /dev/stderr
exit 1
fi

# We're a lengthy background process, so don't eat too much CPU and disk I/O
if [[ "$LOW_PRIORITY" == "yes" ]]; then
	renice '+15' $$ || true
	ionice -c 3 -p $$ || true
fi

export FSARCH=${1:-'i386'}

mkdir -p tmp/$FSARCH

cd tmp/$FSARCH
rm -Rf auto
cp -R ../../etc/auto auto

sed -i "s/@SYSLINUX/$CODENAME/" auto/config

lb clean
lb config
lb build
mv binary.hybrid.iso binary.iso
md5sum binary.iso > binary.iso.md5
mkdir -p ../../builds/`date +%Y%m%d`/$FSARCH
mv binary.* ../../builds/`date +%Y%m%d`/$FSARCH/
rm -f livecd*

cd ../..