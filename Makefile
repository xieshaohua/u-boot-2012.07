#
# (C) Copyright 2000-2012
# Wolfgang Denk, DENX Software Engineering, wd@denx.de.
#
# See file CREDITS for list of people who contributed to this
# project.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundatio; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

VERSION = 2012
PATCHLEVEL = 07
SUBLEVEL =
EXTRAVERSION =
ifneq "$(SUBLEVEL)" ""
U_BOOT_VERSION = $(VERSION).$(PATCHLEVEL).$(SUBLEVEL)$(EXTRAVERSION)
else
U_BOOT_VERSION = $(VERSION).$(PATCHLEVEL)$(EXTRAVERSION)
endif
TIMESTAMP_FILE = $(obj)include/generated/timestamp_autogenerated.h
VERSION_FILE = $(obj)include/generated/version_autogenerated.h

HOSTARCH := $(shell uname -m | \
	sed -e s/i.86/x86/ \
	    -e s/sun4u/sparc64/ \
	    -e s/arm.*/arm/ \
	    -e s/sa110/arm/ \
	    -e s/ppc64/powerpc/ \
	    -e s/ppc/powerpc/ \
	    -e s/macppc/powerpc/\
	    -e s/sh.*/sh/)

HOSTOS := $(shell uname -s | tr '[:upper:]' '[:lower:]' | \
	    sed -e 's/\(cygwin\).*/cygwin/')

# Set shell to bash if possible, otherwise fall back to sh
SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	else if [ -x /bin/bash ]; then echo /bin/bash; \
	else echo sh; fi; fi)

export	HOSTARCH HOSTOS SHELL

# Deal with colliding definitions from tcsh etc.
VENDOR=

OBJTREE		:= $(CURDIR)
SRCTREE		:= $(CURDIR)
TOPDIR		:= $(SRCTREE)
LNDIR		:= $(OBJTREE)
export	TOPDIR SRCTREE OBJTREE

MKCONFIG	:= $(SRCTREE)/mkconfig
export MKCONFIG

# $(obj) and (src) are defined in config.mk but here in main Makefile
# we also need them before config.mk is included which is the case for
# some targets like unconfig, clean, clobber, distclean, etc.
obj :=
src :=
export obj src

# Make sure CDPATH settings don't interfere
unexport CDPATH

#########################################################################

# The "tools" are needed early, so put this first
# Don't include stuff already done in $(LIBS)
SUBDIR_TOOLS = tools
SUBDIRS = $(SUBDIR_TOOLS)

.PHONY : $(SUBDIRS) $(VERSION_FILE) $(TIMESTAMP_FILE)

ifeq ($(obj)include/config.mk,$(wildcard $(obj)include/config.mk))
$(info "++++++++++++++++++++++++++++++++++++++++++")

# Include autoconf.mk before config.mk so that the config options are available
# to all top level build files.  We need the dummy all: target to prevent the
# dependency target in autoconf.mk.dep from being the default.
all:
sinclude $(obj)include/autoconf.mk.dep
sinclude $(obj)include/autoconf.mk

# load ARCH, BOARD, and CPU configuration
include $(obj)include/config.mk
export	ARCH CPU BOARD VENDOR SOC

# load other configuration
include $(TOPDIR)/config.mk

# If board code explicitly specified LDSCRIPT or CONFIG_SYS_LDSCRIPT, use
# that (or fail if absent).  Otherwise, search for a linker script in a
# standard location.
LDSCRIPT := $(TOPDIR)/arch/$(ARCH)/cpu/u-boot.lds

#########################################################################
# U-Boot objects....order is important (i.e. start must be first)

OBJS  = $(CPUDIR)/start.o

OBJS := $(addprefix $(obj),$(OBJS))

LIBS  = lib/libgeneric.o
LIBS += lib/lzma/liblzma.o
LIBS += lib/lzo/liblzo.o
LIBS += lib/zlib/libz.o
#LIBS += $(shell if [ -f board/$(VENDOR)/common/Makefile ]; then echo \
#	"board/$(VENDOR)/common/lib$(VENDOR).o"; fi)
LIBS += $(CPUDIR)/lib$(CPU).o
ifdef SOC
LIBS += $(CPUDIR)/$(SOC)/lib$(SOC).o
endif
LIBS += arch/$(ARCH)/lib/lib$(ARCH).o
LIBS += fs/jffs2/libjffs2.o fs/yaffs2/libyaffs2.o
LIBS += net/libnet.o
LIBS += disk/libdisk.o
LIBS += drivers/mtd/libmtd.o
LIBS += drivers/mtd/nand/libnand.o
LIBS += drivers/mtd/ubi/libubi.o
LIBS += drivers/net/libnet.o
LIBS += drivers/net/phy/libphy.o
LIBS += drivers/rtc/librtc.o
LIBS += drivers/serial/libserial.o
LIBS += common/libcommon.o

LIBS := $(addprefix $(obj),$(sort $(LIBS)))
.PHONY : $(LIBS)

LIBBOARD = board/$(BOARDDIR)/lib$(BOARD).o
LIBBOARD := $(addprefix $(obj),$(LIBBOARD))

# Add GCC lib
PLATFORM_LIBGCC := -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc
PLATFORM_LIBS += $(PLATFORM_LIBGCC)
export PLATFORM_LIBS

# Special flags for CPP when processing the linker script.
# Pass the version down so we can handle backwards compatibility
# on the fly.
LDPPFLAGS += \
	-include $(TOPDIR)/include/u-boot/u-boot.lds.h \
	-DCPUDIR=$(CPUDIR) \
	$(shell $(LD) --version | \
	  sed -ne 's/GNU ld version \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/-DLD_MAJOR=\1 -DLD_MINOR=\2/p')

__OBJS := $(subst $(obj),,$(OBJS))
__LIBS := $(subst $(obj),,$(LIBS)) $(subst $(obj),,$(LIBBOARD))

#########################################################################
#########################################################################

# Always append ALL so that arch config.mk's can add custom ones
ALL-y += $(obj)u-boot.bin $(obj)System.map

ALL-$(CONFIG_NAND_U_BOOT) += $(obj)u-boot-nand.bin

all:		$(ALL-y)

$(obj)u-boot.bin:	$(obj)u-boot
		$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

GEN_UBOOT = \
		UNDEF_SYM=`$(OBJDUMP) -x $(LIBBOARD) $(LIBS) | \
		sed  -n -e 's/.*\($(SYM_PREFIX)__u_boot_cmd_.*\)/-u\1/p'|sort|uniq`;\
		cd $(LNDIR) && $(LD) $(LDFLAGS) $(LDFLAGS_$(@F)) $$UNDEF_SYM $(__OBJS) \
			--start-group $(__LIBS) --end-group $(PLATFORM_LIBS) \
			-Map u-boot.map -o u-boot

$(obj)u-boot:	depend \
		$(SUBDIR_TOOLS) $(OBJS) $(LIBBOARD) $(LIBS) $(LDSCRIPT) $(obj)u-boot.lds
		$(GEN_UBOOT)
ifeq ($(CONFIG_KALLSYMS),y)
		smap=`$(call SYSTEM_MAP,u-boot) | \
			awk '$$2 ~ /[tTwW]/ {printf $$1 $$3 "\\\\000"}'` ; \
		$(CC) $(CFLAGS) -DSYSTEM_MAP="\"$${smap}\"" \
			-c common/system_map.c -o $(obj)common/system_map.o
		$(GEN_UBOOT) $(obj)common/system_map.o
endif

$(OBJS):	depend
		$(MAKE) -C $(CPUDIR) $(notdir $@)

$(LIBS):	depend $(SUBDIR_TOOLS)
		$(MAKE) -C $(dir $(subst $(obj),,$@))

$(LIBBOARD):	depend $(LIBS)
		$(MAKE) -C $(dir $(subst $(obj),,$@))

$(SUBDIRS):	depend
		$(MAKE) -C $@ all

$(LDSCRIPT):	depend
		$(MAKE) -C $(dir $@) $(notdir $@)

$(obj)u-boot.lds: $(LDSCRIPT)
		$(CPP) $(CPPFLAGS) $(LDPPFLAGS) -ansi -D__ASSEMBLY__ -P - <$^ >$@

nand_spl:	$(TIMESTAMP_FILE) $(VERSION_FILE) depend
		$(MAKE) -C nand_spl/board/$(BOARDDIR) all

$(obj)u-boot-nand.bin:	nand_spl $(obj)u-boot.bin
		cat $(obj)nand_spl/u-boot-spl-16k.bin $(obj)u-boot.bin > $(obj)u-boot-nand.bin

onenand_ipl:	$(TIMESTAMP_FILE) $(VERSION_FILE) $(obj)include/autoconf.mk
		$(MAKE) -C onenand_ipl/board/$(BOARDDIR) all

$(obj)u-boot-onenand.bin:	onenand_ipl $(obj)u-boot.bin
		cat $(ONENAND_BIN) $(obj)u-boot.bin > $(obj)u-boot-onenand.bin

$(obj)spl/u-boot-spl.bin:	$(SUBDIR_TOOLS) depend
		$(MAKE) -C spl all

updater:
		$(MAKE) -C tools/updater all

# Explicitly make _depend in subdirs containing multiple targets to prevent
# parallel sub-makes creating .depend files simultaneously.
depend dep:	$(TIMESTAMP_FILE) $(VERSION_FILE) \
		$(obj)include/autoconf.mk \
		$(obj)include/generated/generic-asm-offsets.h \
		$(obj)include/generated/asm-offsets.h
		for dir in $(SUBDIRS) $(CPUDIR) ; do \
			$(MAKE) -C $$dir _depend ; done

TAG_SUBDIRS = $(SUBDIRS)
TAG_SUBDIRS += $(dir $(__LIBS))
TAG_SUBDIRS += include

FIND := find
FINDFLAGS := -L

checkstack:
		$(CROSS_COMPILE)objdump -d $(obj)u-boot \
			`$(FIND) $(obj) -name u-boot-spl -print` | \
			perl $(src)tools/checkstack.pl $(ARCH)

tags ctags:
		ctags -w -o $(obj)ctags `$(FIND) $(FINDFLAGS) $(TAG_SUBDIRS) \
						-name '*.[chS]' -print`

etags:
		etags -a -o $(obj)etags `$(FIND) $(FINDFLAGS) $(TAG_SUBDIRS) \
						-name '*.[chS]' -print`
cscope:
		$(FIND) $(FINDFLAGS) $(TAG_SUBDIRS) -name '*.[chS]' -print > \
						cscope.files
		cscope -b -q -k

SYSTEM_MAP = \
		$(NM) $1 | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		LC_ALL=C sort
$(obj)System.map:	$(obj)u-boot
		@$(call SYSTEM_MAP,$<) > $(obj)System.map

checkthumb:
	@if test $(call cc-version) -lt 0404; then \
		echo -n '*** Your GCC does not produce working '; \
		echo 'binaries in THUMB mode.'; \
		echo '*** Your board is configured for THUMB mode.'; \
		false; \
	fi
#
# Auto-generate the autoconf.mk file (which is included by all makefiles)
#
# This target actually generates 2 files; autoconf.mk and autoconf.mk.dep.
# the dep file is only include in this top level makefile to determine when
# to regenerate the autoconf.mk file.
$(obj)include/autoconf.mk.dep: $(obj)include/config.h include/common.h
	@echo Generating $@ ; \
	set -e ; \
	: Generate the dependancies ; \
	$(CC) -x c -DDO_DEPS_ONLY -M $(CFLAGS) $(CPPFLAGS) \
		-MQ $(obj)include/autoconf.mk include/common.h > $@

$(obj)include/autoconf.mk: $(obj)include/config.h
	@echo Generating $@ ; \
	set -e ; \
	: Extract the config macros ; \
	$(CPP) $(CFLAGS) -DDO_DEPS_ONLY -dM include/common.h | \
		sed -n -f tools/scripts/define2mk.sed > $@.tmp && \
	mv $@.tmp $@

$(obj)include/generated/generic-asm-offsets.h:	$(obj)include/autoconf.mk.dep \
	$(obj)lib/asm-offsets.s
	@echo Generating $@
	tools/scripts/make-asm-offsets $(obj)lib/asm-offsets.s $@

$(obj)lib/asm-offsets.s:	$(obj)include/autoconf.mk.dep \
	$(src)lib/asm-offsets.c
	@mkdir -p $(obj)lib
	$(CC) -DDO_DEPS_ONLY \
		$(CFLAGS) $(CFLAGS_$(BCURDIR)/$(@F)) $(CFLAGS_$(BCURDIR)) \
		-o $@ $(src)lib/asm-offsets.c -c -S

$(obj)include/generated/asm-offsets.h:	$(obj)include/autoconf.mk.dep \
	$(obj)$(CPUDIR)/$(SOC)/asm-offsets.s
	@echo Generating $@
	tools/scripts/make-asm-offsets $(obj)$(CPUDIR)/$(SOC)/asm-offsets.s $@

$(obj)$(CPUDIR)/$(SOC)/asm-offsets.s:	$(obj)include/autoconf.mk.dep
	@mkdir -p $(obj)$(CPUDIR)/$(SOC)
	if [ -f $(src)$(CPUDIR)/$(SOC)/asm-offsets.c ];then \
		$(CC) -DDO_DEPS_ONLY \
		$(CFLAGS) $(CFLAGS_$(BCURDIR)/$(@F)) $(CFLAGS_$(BCURDIR)) \
			-o $@ $(src)$(CPUDIR)/$(SOC)/asm-offsets.c -c -S; \
	else \
		touch $@; \
	fi

#########################################################################
else	# !config.mk
all $(obj)u-boot.bin $(obj)u-boot.dis $(obj)u-boot \
$(filter-out tools,$(SUBDIRS)) \
updater depend dep tags ctags etags cscope $(obj)System.map:
	@echo "System not configured - see README" >&2
	@ exit 1

tools: $(VERSION_FILE) $(TIMESTAMP_FILE)
	$(MAKE) -C $@ all
endif	# config.mk

$(VERSION_FILE):
		@mkdir -p $(dir $(VERSION_FILE))
		@( localvers='$(shell $(TOPDIR)/tools/setlocalversion $(TOPDIR))' ; \
		   printf '#define PLAIN_VERSION "%s%s"\n' \
			"$(U_BOOT_VERSION)" "$${localvers}" ; \
		   printf '#define U_BOOT_VERSION "U-Boot %s%s"\n' \
			"$(U_BOOT_VERSION)" "$${localvers}" ; \
		) > $@.tmp
		@( printf '#define CC_VERSION_STRING "%s"\n' \
		 '$(shell $(CC) --version | head -n 1)' )>>  $@.tmp
		@( printf '#define LD_VERSION_STRING "%s"\n' \
		 '$(shell $(LD) -v | head -n 1)' )>>  $@.tmp
		@cmp -s $@ $@.tmp && rm -f $@.tmp || mv -f $@.tmp $@

$(TIMESTAMP_FILE):
		@mkdir -p $(dir $(TIMESTAMP_FILE))
		@LC_ALL=C date +'#define U_BOOT_DATE "%b %d %C%y"' > $@.tmp
		@LC_ALL=C date +'#define U_BOOT_TIME "%T"' >> $@.tmp
		@cmp -s $@ $@.tmp && rm -f $@.tmp || mv -f $@.tmp $@

easylogo env gdb:
	$(MAKE) -C tools/$@ all MTD_VERSION=${MTD_VERSION}
gdbtools: gdb

tools-all: easylogo env gdb $(VERSION_FILE) $(TIMESTAMP_FILE)
	$(MAKE) -C tools HOST_TOOLS_ALL=y

.PHONY : CHANGELOG
CHANGELOG:
	git log --no-merges U-Boot-1_1_5.. | \
	unexpand -a | sed -e 's/\s\s*$$//' > $@

include/license.h: tools/bin2header COPYING
	cat COPYING | gzip -9 -c | ./tools/bin2header license_gzip > include/license.h
#########################################################################

unconfig:
	@rm -f $(obj)include/config.h $(obj)include/config.mk \
		$(obj)board/*/config.tmp $(obj)board/*/*/config.tmp \
		$(obj)include/autoconf.mk $(obj)include/autoconf.mk.dep

%_config::	unconfig
	@$(MKCONFIG) -A $(@:_config=)

sinclude $(obj).boards.depend
$(obj).boards.depend:	boards.cfg
	@awk '(NF && $$1 !~ /^#/) { print $$1 ": " $$1 "_config; $$(MAKE)" }' $< > $@

#
# Functions to generate common board directory names
#
lcname	= $(shell echo $(1) | sed -e 's/\(.*\)_config/\L\1/')
ucname	= $(shell echo $(1) | sed -e 's/\(.*\)_config/\U\1/')

#########################################################################
#########################################################################

clean:
	@rm -f $(obj)examples/standalone/82559_eeprom			  \
	       $(obj)examples/standalone/atmel_df_pow2			  \
	       $(obj)examples/standalone/eepro100_eeprom		  \
	       $(obj)examples/standalone/hello_world			  \
	       $(obj)examples/standalone/interrupt			  \
	       $(obj)examples/standalone/mem_to_mem_idma2intr		  \
	       $(obj)examples/standalone/sched				  \
	       $(obj)examples/standalone/smc911{11,x}_eeprom		  \
	       $(obj)examples/standalone/test_burst			  \
	       $(obj)examples/standalone/timer
	@rm -f $(obj)examples/api/demo{,.bin}
	@rm -f $(obj)tools/bmp_logo	   $(obj)tools/easylogo/easylogo  \
	       $(obj)tools/env/{fw_printenv,fw_setenv}			  \
	       $(obj)tools/envcrc					  \
	       $(obj)tools/gdb/{astest,gdbcont,gdbsend}			  \
	       $(obj)tools/gen_eth_addr    $(obj)tools/img2srec		  \
	       $(obj)tools/mk{env,}image   $(obj)tools/mpc86x_clk	  \
	       $(obj)tools/mk{smdk5250,}spl				  \
	       $(obj)tools/ncb		   $(obj)tools/ubsha1
	@rm -f $(obj)board/cray/L1/{bootscript.c,bootscript.image}	  \
	       $(obj)board/matrix_vision/*/bootscript.img		  \
	       $(obj)board/voiceblue/eeprom 				  \
	       $(obj)u-boot.lds						  \
	       $(obj)arch/blackfin/cpu/bootrom-asm-offsets.[chs]	  \
	       $(obj)arch/blackfin/cpu/init.{lds,elf}
	@rm -f $(obj)include/bmp_logo.h
	@rm -f $(obj)include/bmp_logo_data.h
	@rm -f $(obj)lib/asm-offsets.s
	@rm -f $(obj)include/generated/asm-offsets.h
	@rm -f $(obj)$(CPUDIR)/$(SOC)/asm-offsets.s
	@rm -f $(obj)nand_spl/{u-boot.lds,u-boot-nand_spl.lds,u-boot-spl,u-boot-spl.map,System.map}
	@rm -f $(obj)onenand_ipl/onenand-{ipl,ipl.bin,ipl.map}
	@rm -f $(obj)onenand_ipl/u-boot.lds
	@rm -f $(obj)spl/{u-boot-spl,u-boot-spl.bin,u-boot-spl.lds,u-boot-spl.map}
	@rm -f $(obj)MLO
	@rm -f $(TIMESTAMP_FILE) $(VERSION_FILE)
	@find $(OBJTREE) -type f \
		\( -name 'core' -o -name '*.bak' -o -name '*~' -o -name '*.su' \
		-o -name '*.o'	-o -name '*.a' -o -name '*.exe'	\) -print \
		| xargs rm -f

# Removes everything not needed for testing u-boot
tidy:	clean
	@find $(OBJTREE) -type f \( -name '*.depend*' \) -print | xargs rm -f

clobber:	tidy
	@find $(OBJTREE) -type f \( -name '*.srec' \
		-o -name '*.bin' -o -name u-boot.img \) \
		-print0 | xargs -0 rm -f
	@rm -f $(OBJS) $(obj)*.bak $(obj)ctags $(obj)etags $(obj)TAGS \
		$(obj)cscope.* $(obj)*.*~
	@rm -f $(obj)u-boot $(obj)u-boot.map $(obj)u-boot.hex $(ALL-y)
	@rm -f $(obj)u-boot.kwb
	@rm -f $(obj)u-boot.imx
	@rm -f $(obj)u-boot.ubl
	@rm -f $(obj)u-boot.ais
	@rm -f $(obj)u-boot.dtb
	@rm -f $(obj)u-boot.sb
	@rm -f $(obj)u-boot.spr
	@rm -f $(obj)tools/xway-swap-bytes
	@rm -f $(obj)arch/powerpc/cpu/mpc824x/bedbug_603e.c
	@rm -f $(obj)arch/powerpc/cpu/mpc83xx/ddr-gen?.c
	@rm -fr $(obj)include/asm/proc $(obj)include/asm/arch $(obj)include/asm
	@rm -fr $(obj)include/generated
	@[ ! -d $(obj)nand_spl ] || find $(obj)nand_spl -name "*" -type l -print | xargs rm -f
	@[ ! -d $(obj)onenand_ipl ] || find $(obj)onenand_ipl -name "*" -type l -print | xargs rm -f
	@rm -f $(obj)dts/*.tmp

mrproper \
distclean:	clobber unconfig
ifneq ($(OBJTREE),$(SRCTREE))
	rm -rf $(obj)*
endif

backup:
	F=`basename $(TOPDIR)` ; cd .. ; \
	gtar --force-local -zcvf `LC_ALL=C date "+$$F-%Y-%m-%d-%T.tar.gz"` $$F

#########################################################################
