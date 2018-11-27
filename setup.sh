#!/bin/sh -e

APT_PKGS="binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools gpart binutils git lib32ncurses5-dev python-m2crypto gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev autoconf libtool libglib2.0-dev libarchive-dev python-git xterm sed cvs subversion coreutils texi2html bc docbook-utils python-pysqlite2 help2man make gcc g++ desktop-file-utils libgl1-mesa-dev libglu1-mesa-dev mercurial automake groff curl lzop asciidoc u-boot-tools mtd-utils device-tree-compiler"
REPO="https://github.com/uvdl/debian-var.git"
BRANCH="iris2"
BUILD_PATH="var_som_mx6_debian"
BUILD_SCRIPT="make_var_som_mx6_debian.sh"

sudo apt-get update
sudo apt-get install ${APT_PKGS}

git clone ${REPO} -b ${BRANCH} ${BUILD_PATH}

( cd ${BUILD_PATH} && ./${BUILD_SCRIPT} -c deploy )
