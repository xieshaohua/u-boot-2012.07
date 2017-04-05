
OBJTREE		:= $(CURDIR)
SRCTREE		:= $(CURDIR)
TOPDIR		:= $(CURDIR)
LNDIR		:= $(OBJTREE)
export	TOPDIR SRCTREE OBJTREE

# $(obj) and (src) are defined in config.mk but here in main Makefile
# we also need them before config.mk is included which is the case for
# some targets like unconfig, clean, clobber, distclean, etc.
obj :=
src :=
export obj src

# Make sure CDPATH settings don't interfere
#unexport CDPATH

#########################################################################

#ifeq ($(obj)include/config.mk,$(wildcard $(obj)include/config.mk))

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
LIBS += $(CPUDIR)/lib$(CPU).o
LIBS += $(CPUDIR)/$(SOC)/lib$(SOC).o
LIBS += arch/$(ARCH)/lib/lib$(ARCH).o
LIBS += fs/jffs2/libjffs2.o fs/yaffs2/libyaffs2.o
LIBS += net/libnet.o
LIBS += disk/libdisk.o
LIBS += drivers/mtd/libmtd.o
LIBS += drivers/mtd/nand/libnand.o
LIBS += drivers/mtd/ubi/libubi.o
LIBS += drivers/net/libnet.o
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

ALL-$(CONFIG_NAND_U_BOOT) += $(obj)u-boot-spl.bin

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
		$(OBJS) $(LIBBOARD) $(LIBS) $(LDSCRIPT) $(obj)u-boot.lds
		$(GEN_UBOOT)

$(OBJS):	depend
		$(MAKE) -C $(CPUDIR) $(notdir $@)

$(LIBS):	depend
		$(MAKE) -C $(dir $(subst $(obj),,$@))

$(LIBBOARD):	depend $(LIBS)
		$(MAKE) -C $(dir $(subst $(obj),,$@))

$(LDSCRIPT):	depend
		$(MAKE) -C $(dir $@) $(notdir $@)

$(obj)u-boot.lds: $(LDSCRIPT)
		$(CPP) $(CPPFLAGS) $(LDPPFLAGS) -ansi -D__ASSEMBLY__ -P - <$^ >$@

spl:	depend
		$(MAKE) -C spl all

$(obj)u-boot-spl.bin:	spl $(obj)u-boot.bin
		cat $(obj)spl/spl-4k.bin $(obj)u-boot.bin > $(obj)u-boot-spl.bin

depend dep:	$(obj)include/autoconf.mk \
		$(obj)include/generated/generic-asm-offsets.h \
		$(obj)include/generated/asm-offsets.h
		for dir in $(CPUDIR) ; do \
			$(MAKE) -C $$dir _depend ; done

SYSTEM_MAP = \
		$(NM) $1 | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		LC_ALL=C sort
$(obj)System.map:	$(obj)u-boot
		@$(call SYSTEM_MAP,$<) > $(obj)System.map

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
unconfig:
#	@rm -f $(obj)include/config.h $(obj)include/config.mk
	@rm -f $(obj)board/*/config.tmp $(obj)board/*/*/config.tmp
	@rm -f $(obj)include/autoconf.mk $(obj)include/autoconf.mk.dep

#########################################################################
clean:	unconfig
	@rm -f u-boot.lds					  \
	@rm -f include/bmp_logo.h
	@rm -f include/bmp_logo_data.h
	@rm -f lib/asm-offsets.s
	@rm -f include/generated/asm-offsets.h
	@rm -f $(CPUDIR)/$(SOC)/asm-offsets.s
	@rm -f spl/spl spl/spl.map
	@rm -f $(obj)MLO
	@find $(OBJTREE) -type f \
		\( -name 'core' -o -name '*.bak' -o -name '*~' -o -name '*.su' \
		-o -name '*.o'	-o -name '*.a' -o -name '*.exe'	\) -print \
		| xargs rm -f
	@find $(OBJTREE) -type f \( -name '*.depend*' \) -print | xargs rm -f
	@rm -f $(OBJS) $(obj)*.bak $(obj)ctags $(obj)etags $(obj)TAGS \
		$(obj)cscope.* $(obj)*.*~
	@rm -f $(obj)u-boot $(obj)u-boot.map $(obj)u-boot.hex $(ALL-y)
	@rm -rf $(obj)include/generated

#########################################################################
