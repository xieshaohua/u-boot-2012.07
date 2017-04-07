
TOPDIR		:= $(CURDIR)
export	TOPDIR

#########################################################################
# Include autoconf.mk before config.mk so that the config options are available
# to all top level build files.
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

PLATFORM_LIBS := $(TOPDIR)/arch/arm/lib/eabi_compat.o
# Add GCC lib
PLATFORM_LIBGCC := -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc
PLATFORM_LIBS += $(PLATFORM_LIBGCC)


all:	u-boot.bin u-boot-spl.bin

u-boot.bin:	u-boot
		$(OBJCOPY) --gap-fill=0xff -O binary $< $@

GEN_UBOOT = \
		UNDEF_SYM=`$(OBJDUMP) -x $(LIBBOARD) $(LIBS) | \
		sed -n -e 's/.*\($(SYM_PREFIX)__u_boot_cmd_.*\)/-u\1/p'|sort|uniq`;\
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

depend:	include/autoconf.mk

# Auto-generate the autoconf.mk file (which is included by all makefiles)
include/autoconf.mk:
	@echo Generating $@ ; \
	set -e ; \
	: Extract the config macros ; \
	$(CPP) $(CFLAGS) -DDO_DEPS_ONLY -dM include/common.h | \
		sed -n -f tools/define2mk.sed > $@.tmp && \
	mv $@.tmp $@

#########################################################################
clean:
	@find $(TOPDIR) -type f -name '*.o' -print | xargs rm -f
	@rm -f u-boot u-boot.bin u-boot-spl.bin u-boot.map
	@rm -f include/autoconf.mk
	@make -C spl clean

#########################################################################
