# Automation for instructions
# http://variwiki.com/index.php?title=Debian_Build_Release&release=RELEASE_STRETCH_V2.0_VAR-SOM-MX6

SHELL := /bin/bash
CPUS := $(shell nproc)
SUDO := $(shell test $${EUID} -ne 0 && echo "sudo")
LANG := en_US.UTF-8
.EXPORT_ALL_VARIABLES:

LOGDIR=$(CURDIR)/log
MACHINE=imx6q-var-dart
OUTPUT=$(CURDIR)/output
PKGDEPS1=binfmt-support qemu qemu-user-static debootstrap kpartx \
lvm2 dosfstools gpart binutils git lib32ncurses5-dev python-m2crypto gawk wget \
git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev
PKGDEPS2=autoconf libtool libglib2.0-dev libarchive-dev python-git xterm sed cvs subversion \
coreutils texi2html bc docbook-utils python-pysqlite2 help2man make gcc g++ \
desktop-file-utils libgl1-mesa-dev libglu1-mesa-dev mercurial automake groff curl \
lzop asciidoc u-boot-tools mtd-utils device-tree-compiler
PLATFORM_GIT=https://github.com/uvdl/debian-var.git
PLATFORM_BRANCH=iris2
PROJECT=debian-uvdl
PROJECT_REMOTE := $(USER)
PROJECT_TAG := core
SCRIPT_NAME=make_var_som_mx6_debian.sh
SD_SIZE_IN_GB=4
SRC=$(CURDIR)/src

# https://stackoverflow.com/questions/16488581/looking-for-well-logged-make-output
# Invoke this with $(call LOG,<cmdline>)
define LOG
  @echo "$$(date --iso-8601='ns'): $1 started." >>$(LOGDIR)/make.log
  ($1) 2>&1 | tee -a $(LOGDIR)/build.log && echo "$$(date --iso-8601='ns'): $1 completed." >>$(LOGDIR)/make.log
endef

.PHONY: build-bootloader build-kernel build-modules build-rootfs build-sdcard
.PHONY: all clean deps docker-deploy docker-image id locale see usage

default: usage

$(LOGDIR):
	mkdir -p $(LOGDIR)

$(OUTPUT)/rootfs.tar.gz: $(SRC) $(OUTPUT)/uImage $(OUTPUT)/$(MACHINE).dtb
	$(SUDO) ./$(SCRIPT_NAME) -c rootfs
	$(SUDO) ./$(SCRIPT_NAME) -c rtar

$(OUTPUT)/sd.img: $(SRC) $(OUTPUT)/u-boot.img.mmc $(OUTPUT)/uImage $(OUTPUT)/$(MACHINE).dtb $(OUTPUT)/rootfs.tar.gz
	dd if=/dev/zero of=$@ bs=1G count=$(SD_SIZE_IN_GB)
	$(SUDO) losetup -f $@
	dev=$(shell losetup -l | grep $@ | cut -f1 -d' ') && $(SUDO) ./$(SCRIPT_NAME) -c sdcard -d $$dev

$(OUTPUT)/$(MACHINE).dtb: $(SRC) $(OUTPUT)/uImage
	$(SUDO) ./$(SCRIPT_NAME) -c modules

$(OUTPUT)/uImage: $(SRC)
	$(SUDO) ./$(SCRIPT_NAME) -c kernel

$(OUTPUT)/u-boot.img.mmc: $(SRC)
	$(SUDO) ./$(SCRIPT_NAME) -c bootloader

$(SRC):
	$(SUDO) ./$(SCRIPT_NAME) -c deploy

all: $(LOGDIR)
	$(call LOG, $(MAKE) deps )
	$(call LOG, $(MAKE) see )
	$(call LOG, $(MAKE) $(OUTPUT)/sd.img )

build-bootloader: $(LOGDIR)
	$(call LOG, $(MAKE) $(OUTPUT)/u-boot.img.mmc )

build-kernel: $(LOGDIR)
	$(call LOG, $(MAKE) $(OUTPUT)/uImage )

build-modules: $(LOGDIR)
	$(call LOG, $(MAKE) $(OUTPUT)/$(MACHINE).dtb )

build-rootfs: $(LOGDIR)
	$(call LOG, $(MAKE) $(OUTPUT)/rootfs.tar.gz )

build-sdcard: $(LOGDIR)
	$(call LOG, $(MAKE) $(OUTPUT)/sd.img )

clean:
	-rm -f $(LOGDIR)/build.log $(LOGDIR)/make.log
	-rm -f $(OUTPUT)/u-boot.img.mmc $(OUTPUT)/uImage $(OUTPUT)/$(MACHINE).dtb $(OUTPUT)/rootfs.tar.gz

deps:
	$(SUDO) apt-get update
	$(SUDO) apt-get install -y $(PKGDEPS1)
	$(SUDO) apt-get install -y $(PKGDEPS2)

Dockerfile: Makefile
	@echo "FROM ubuntu:16.04" > $@
	@echo "RUN apt-get -y update && apt-get -y upgrade" >> $@
	@echo "RUN apt-get -y install git make sudo vim" >> $@
ifeq ($(PROJECT_TAG),base)
	@echo "RUN apt-get -y install $(PKGDEPS1) && apt-get -y install $(PKGDEPS2)" >> $@
endif
	@echo "RUN apt-get -y install locales && locale-gen $(LANG) && update-locale LC ALL=$(LANG) LANG=$(LANG)" >> $@
	@echo "WORKDIR /home/$(PROJECT)" >> $@
	@echo "COPY . /home/$(PROJECT)" >> $@
	@echo "CMD \"$(SHELL)\"" >> $@

docker-deploy: docker-image
	docker tag $(PROJECT):$(PROJECT_TAG) $(PROJECT_REMOTE)/$(PROJECT):$(PROJECT_TAG)
	docker push $(PROJECT_REMOTE)/$(PROJECT):$(PROJECT_TAG)

docker-image: Dockerfile
	docker build -t $(PROJECT):$(PROJECT_TAG) .

id:
	git config --global user.name "UVDL Developer"
	git config --global user.email "uvdl@ornl.gov"
	git config --global push.default matching
	git config --global credential.helper "cache --timeout=5400"

locale:
	# https://wiki.yoctoproject.org/wiki/TipsAndTricks/ResolvingLocaleIssues
	$(SUDO) apt-get install locales
	$(SUDO) locale-gen $(LANG)
	$(SUDO) update-locale LC ALL=$(LANG) LANG=$(LANG)

see:
	@echo "CPUS=$(CPUS)"
	@echo "SUDO=$(SUDO)"
	@echo "*** Build Commands ***"
	@$(MAKE) --no-print-directory -n $(OUTPUT)/sd.img
	@echo "**********************"
	@echo "Use: \"make all\" to perform this build"

define USAGE
	@echo "Usage:"
	@echo " make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  all           -- perform all steps including dependencies to produce sdcard image"
	@echo "  build-<what>"
	@echo "    bootloader  -- just the u-boot image"
	@echo "    kernel      -- just the kernel image"
	@echo "    modules     -- just the modules and the .dtb files"
	@echo "    rootfs      -- just root filesystem"
	@echo "    sdcard      -- produce the sdcard image"
	@echo "  clean         -- remove build artifacts"
	@echo "  deps          -- ensure OS has required dependencies installed"
	@echo "  docker-<command>"
	@echo "    deploy      -- upload tagged image to dockerhub"
	@echo "    image       -- generate a Dockerfile and a core build environment"
	@echo "  id            -- setup git global values"
	@echo "  locale        -- configure locale settings (needed for YOCTO builds)"
	@echo "  see           -- report configuration settings"
	@echo ""
endef

usage:
	@$(call USAGE, $(PROJECT))
