
OBJTREE		:= $(CURDIR)
SRCTREE		:= $(CURDIR)
TOPDIR		:= $(CURDIR)
export	TOPDIR SRCTREE OBJTREE

#########################################################################
# Include autoconf.mk before config.mk so that the config options are available
# to all top level build files.  We need the dummy all: target to prevent the
# dependency target in autoconf.mk.dep from being the default.
all:
sinclude include/autoconf.mk.dep
sinclude include/autoconf.mk

# load other configuration
include $(TOPDIR)/config.mk

#########################################################################
# U-Boot objects....order is important (i.e. start must be first)

OBJS  = $(CPUDIR)/start.o

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

LIBS := $(sort $(LIBS))
.PHONY : $(LIBS)

LIBBOARD = board/$(BOARD)/lib$(BOARD).o

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

#########################################################################
#########################################################################
all:	u-boot.bin u-boot-spl.bin System.map

u-boot.bin:	u-boot
		$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

GEN_UBOOT = \
		UNDEF_SYM=`$(OBJDUMP) -x $(LIBBOARD) $(LIBS) | \
		sed  -n -e 's/.*\($(SYM_PREFIX)__u_boot_cmd_.*\)/-u\1/p'|sort|uniq`;\
		$(LD) $(LDFLAGS) $(LDFLAGS_$(@F)) $$UNDEF_SYM $(OBJS) \
			--start-group $(LIBS) $(LIBBOARD) --end-group $(PLATFORM_LIBS) \
			-Map u-boot.map -o u-boot

u-boot:	depend $(OBJS) $(LIBBOARD) $(LIBS) u-boot.lds
		$(GEN_UBOOT)

$(OBJS):	depend
		$(MAKE) -C $(CPUDIR) $(notdir $@)

$(LIBS):	depend
		$(MAKE) -C $(dir $@)

$(LIBBOARD):	depend $(LIBS)
		$(MAKE) -C $(dir $@)

spl:	depend
		$(MAKE) -C spl all

u-boot-spl.bin:	spl u-boot.bin
		cat spl/spl-4k.bin u-boot.bin > u-boot-spl.bin

depend:	include/autoconf.mk \
		include/generated/generic-asm-offsets.h \
		include/generated/asm-offsets.h

SYSTEM_MAP = \
		$(NM) $1 | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		LC_ALL=C sort
System.map:	u-boot
		@$(call SYSTEM_MAP,$<) > System.map

# Auto-generate the autoconf.mk file (which is included by all makefiles)
#
# This target actually generates 2 files; autoconf.mk and autoconf.mk.dep.
# the dep file is only include in this top level makefile to determine when
# to regenerate the autoconf.mk file.
include/autoconf.mk.dep:
	@echo Generating $@ ; \
	set -e ; \
	: Generate the dependancies ; \
	$(CC) -x c -DDO_DEPS_ONLY -M $(CFLAGS) $(CPPFLAGS) \
		-MQ include/autoconf.mk include/common.h > $@

include/autoconf.mk:
	@echo Generating $@ ; \
	set -e ; \
	: Extract the config macros ; \
	$(CPP) $(CFLAGS) -DDO_DEPS_ONLY -dM include/common.h | \
		sed -n -f tools/define2mk.sed > $@.tmp && \
	mv $@.tmp $@

include/generated/generic-asm-offsets.h:	include/autoconf.mk.dep \
	lib/asm-offsets.s
	@echo Generating $@
	tools/make-asm-offsets lib/asm-offsets.s $@

lib/asm-offsets.s:	include/autoconf.mk.dep \
	lib/asm-offsets.c
	@mkdir -p lib
	$(CC) -DDO_DEPS_ONLY \
		$(CFLAGS) $(CFLAGS_$(BCURDIR)/$(@F)) $(CFLAGS_$(BCURDIR)) \
		-o $@ lib/asm-offsets.c -c -S

include/generated/asm-offsets.h:	include/autoconf.mk.dep \
	$(CPUDIR)/$(SOC)/asm-offsets.s
	@echo Generating $@
	tools/make-asm-offsets $(CPUDIR)/$(SOC)/asm-offsets.s $@

$(CPUDIR)/$(SOC)/asm-offsets.s:	include/autoconf.mk.dep
	@mkdir -p $(CPUDIR)/$(SOC)
	if [ -f $(CPUDIR)/$(SOC)/asm-offsets.c ];then \
		$(CC) -DDO_DEPS_ONLY \
		$(CFLAGS) $(CFLAGS_$(BCURDIR)/$(@F)) $(CFLAGS_$(BCURDIR)) \
			-o $@ $(CPUDIR)/$(SOC)/asm-offsets.c -c -S; \
	else \
		touch $@; \
	fi

#########################################################################
clean:
	@rm -f lib/asm-offsets.s
	@rm -f include/generated/asm-offsets.h
	@rm -f $(CPUDIR)/$(SOC)/asm-offsets.s
	@rm -f spl/spl spl/spl.map
	@find $(OBJTREE) -type f \( -name '*.o'	-o -name '*.a' \) -print | xargs rm -f
	@find $(OBJTREE) -type f \( -name '*.depend*' \) -print | xargs rm -f
	@rm -f u-boot u-boot.bin u-boot-spl.bin u-boot.map System.map
	@rm -rf include/generated
	@rm -f include/autoconf.mk include/autoconf.mk.dep
	@rm -f spl/spl.bin spl/spl-4k.bin

#########################################################################
