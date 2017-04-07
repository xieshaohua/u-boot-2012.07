
CROSS_COMPILE ?= arm-linux-

# Include the make variables (CC, etc...)
AS	= $(CROSS_COMPILE)as
LD	= $(CROSS_COMPILE)ld
CC	= $(CROSS_COMPILE)gcc
CPP	= $(CC) -E
AR	= $(CROSS_COMPILE)ar
NM	= $(CROSS_COMPILE)nm
LDR	= $(CROSS_COMPILE)ldr
STRIP	= $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

#########################################################################

# Load generated board configuration
sinclude $(TOPDIR)/include/autoconf.mk

ARCH   = arm
CPU    = arm920t
BOARD  = smdk2440
SOC    = s3c2440

CPUDIR=arch/$(ARCH)/cpu/$(CPU)

#########################################################################

PLATFORM_CPPFLAGS += -DCONFIG_ARM -D__ARM__ -marm -mno-thumb-interwork -mabi=aapcs-linux -march=armv4

# include board specific rules
ifndef CONFIG_NAND_SPL
CONFIG_SYS_TEXT_BASE = 0x33F00000
else
CONFIG_SYS_TEXT_BASE = 0
endif

#########################################################################

gccincdir := $(shell $(CC) -print-file-name=include)

CPPFLAGS := -g -Os -fno-common -ffixed-r8 -msoft-float -D__KERNEL__ -DCONFIG_SYS_TEXT_BASE=$(CONFIG_SYS_TEXT_BASE)	\
			-I$(TOPDIR)/include -fno-builtin -ffreestanding -nostdinc -isystem $(gccincdir) -pipe $(PLATFORM_CPPFLAGS)

CFLAGS := $(CPPFLAGS) -Wall -Wstrict-prototypes -fno-stack-protector -Wno-format-nonliteral -Wno-format-security


AFLAGS := -D__ASSEMBLY__ $(CPPFLAGS)

LDFLAGS_u-boot += -pie -T u-boot.lds -Bstatic -Ttext $(CONFIG_SYS_TEXT_BASE)

#########################################################################

export AS LD CC CPP AR NM STRIP OBJCOPY OBJDUMP MAKE
export PLATFORM_CPPFLAGS CPPFLAGS CFLAGS AFLAGS

#########################################################################

%.s:	%.S
	$(CPP) $(AFLAGS) -o $@ $<
%.o:	%.S
	$(CC)  $(AFLAGS) -o $@ $< -c
%.o:	%.c
	$(CC)  $(CFLAGS) -o $@ $< -c
%.i:	%.c
	$(CPP) $(CFLAGS) -o $@ $< -c
%.s:	%.c
	$(CC)  $(CFLAGS) -o $@ $< -c -S

#########################################################################

# If the list of objects to link is empty, just create an empty built-in.o
cmd_link_o_target = $(if $(strip $1),\
		      $(LD) $(LDFLAGS) -r -o $@ $1,\
		      rm -f $@; $(AR) rcs $@ )

#########################################################################
