#########################################################################

dir :=
obj :=
src :=

PLATFORM_RELFLAGS =
PLATFORM_CPPFLAGS =
PLATFORM_LDFLAGS =

#########################################################################

HOSTCFLAGS	= -Wall -Wstrict-prototypes -O2 -fomit-frame-pointer

#
# Mac OS X / Darwin's C preprocessor is Apple specific.  It
# generates numerous errors and warnings.  We want to bypass it
# and use GNU C's cpp.	To do this we pass the -traditional-cpp
# option to the compiler.  Note that the -traditional-cpp flag
# DOES NOT have the same semantics as GNU C's flag, all it does
# is invoke the GNU preprocessor in stock ANSI/ISO C fashion.
#
# Apple's linker is similar, thanks to the new 2 stage linking
# multiple symbol definitions are treated as errors, hence the
# -multiply_defined suppress option to turn off this error.
#
HOSTCC		= gcc

# We build some files with extra pedantic flags to try to minimize things
# that won't build on some weird host compiler -- though there are lots of
# exceptions for files that aren't complaint.

HOSTCFLAGS_NOPED = $(filter-out -pedantic,$(HOSTCFLAGS))
HOSTCFLAGS	+= -pedantic

#########################################################################
#
# Option checker, gcc version (courtesy linux kernel) to ensure
# only supported compiler options are used
#
CC_OPTIONS_CACHE_FILE := $(OBJTREE)/include/generated/cc_options.mk
CC_TEST_OFILE := $(OBJTREE)/include/generated/cc_test_file.o

-include $(CC_OPTIONS_CACHE_FILE)

cc-option-sys = $(shell mkdir -p $(dir $(CC_TEST_OFILE)); \
		if $(CC) $(CFLAGS) $(1) -S -xc /dev/null -o $(CC_TEST_OFILE) \
		> /dev/null 2>&1; then \
		echo 'CC_OPTIONS += $(strip $1)' >> $(CC_OPTIONS_CACHE_FILE); \
		echo "$(1)"; fi)

cc-option = $(strip $(if $(findstring $1,$(CC_OPTIONS)),$1,$(if $(call cc-option-sys,$1),$1,$2)))

# cc-version
# Usage gcc-ver := $(call cc-version)
cc-version = $(shell $(SHELL) $(SRCTREE)/tools/gcc-version.sh $(CC))

#
# Include the make variables (CC, etc...)
#
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
RANLIB	= $(CROSS_COMPILE)RANLIB

#########################################################################

# Load generated board configuration
sinclude $(OBJTREE)/include/autoconf.mk

ARCH   = arm
CPU    = arm920t
BOARD  = smdk2440
SOC    = s3c2440

# Some architecture config.mk files need to know what CPUDIR is set to,
# so calculate CPUDIR before including ARCH/SOC/CPU config.mk files.
# Check if arch/$ARCH/cpu/$CPU exists, otherwise assume arch/$ARCH/cpu contains
# CPU-specific code.
CPUDIR=arch/$(ARCH)/cpu/$(CPU)
ifneq ($(SRCTREE)/$(CPUDIR),$(wildcard $(SRCTREE)/$(CPUDIR)))
$(info "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
CPUDIR=arch/$(ARCH)/cpu
endif

#########################################################################

##### include architecture dependend rules
CROSS_COMPILE ?= arm-linux-
PLATFORM_CPPFLAGS += -DCONFIG_ARM -D__ARM__

# Choose between ARM/Thumb instruction sets
PF_CPPFLAGS_ARM := $(call cc-option,-marm,) $(call cc-option,-mno-thumb-interwork,)

# Try if EABI is supported, else fall back to old API,
# i. e. for example:
# - with ELDK 4.2 (EABI supported), use:
#	-mabi=aapcs-linux
# - with ELDK 4.1 (gcc 4.x, no EABI), use:
#	-mabi=apcs-gnu
# - with ELDK 3.1 (gcc 3.x), use:
#	-mapcs-32
PF_CPPFLAGS_ABI := $(call cc-option,\
			-mabi=aapcs-linux,\
			$(call cc-option,\
				-mapcs-32,\
				$(call cc-option,\
					-mabi=apcs-gnu,\
				)\
			)\
		)
PLATFORM_CPPFLAGS += $(PF_CPPFLAGS_ARM) $(PF_CPPFLAGS_ABI)

# For EABI, make sure to provide raise()
ifneq (,$(findstring -mabi=aapcs-linux,$(PLATFORM_CPPFLAGS)))
# This file is parsed many times, so the string may get added multiple
# times. Also, the prefix needs to be different based on whether
# CONFIG_SPL_BUILD is defined or not. 'filter-out' the existing entry
# before adding the correct one.
PLATFORM_LIBS := $(OBJTREE)/arch/arm/lib/eabi_compat.o \
	$(filter-out %/arch/arm/lib/eabi_compat.o, $(PLATFORM_LIBS))
endif

# needed for relocation
ifndef CONFIG_NAND_SPL
LDFLAGS_u-boot += -pie
endif

sinclude $(TOPDIR)/$(CPUDIR)/config.mk		# include  CPU	specific rules

##### include  SoC	specific rules
PLATFORM_RELFLAGS += -fno-common -ffixed-r8 -msoft-float
PLATFORM_CPPFLAGS += -march=armv4
PF_RELFLAGS_SLB_AT := $(call cc-option,-mshort-load-bytes,$(call cc-option,-malignment-traps,))
PLATFORM_RELFLAGS += $(PF_RELFLAGS_SLB_AT)

# include board specific rules
ifndef CONFIG_NAND_SPL
CONFIG_SYS_TEXT_BASE = 0x33F00000
#CONFIG_SYS_TEXT_BASE = 0
else
CONFIG_SYS_TEXT_BASE = 0
endif

#########################################################################

# We don't actually use $(ARFLAGS) anywhere anymore, so catch people
# who are porting old code to latest mainline but not updating $(AR).
ARFLAGS = $(error update your Makefile to use cmd_link_o_target and not AR)
RELFLAGS= $(PLATFORM_RELFLAGS)
DBGFLAGS= -g # -DDEBUG
OPTFLAGS= -Os #-fomit-frame-pointer

OBJCFLAGS += --gap-fill=0xff

gccincdir := $(shell $(CC) -print-file-name=include)

CPPFLAGS := $(DBGFLAGS) $(OPTFLAGS) $(RELFLAGS)		\
	-D__KERNEL__

ifneq ($(CONFIG_SYS_TEXT_BASE),)
CPPFLAGS += -DCONFIG_SYS_TEXT_BASE=$(CONFIG_SYS_TEXT_BASE)
endif

CPPFLAGS += -I$(TOPDIR)/include
CPPFLAGS += -fno-builtin -ffreestanding -nostdinc	\
	-isystem $(gccincdir) -pipe $(PLATFORM_CPPFLAGS)

CFLAGS := $(CPPFLAGS) -Wall -Wstrict-prototypes

CFLAGS_SSP := $(call cc-option,-fno-stack-protector)
CFLAGS += $(CFLAGS_SSP)
# Some toolchains enable security related warning flags by default,
# but they don't make much sense in the u-boot world, so disable them.
CFLAGS_WARN := $(call cc-option,-Wno-format-nonliteral) \
	       $(call cc-option,-Wno-format-security)
CFLAGS += $(CFLAGS_WARN)

# Report stack usage if supported
CFLAGS_STACK := $(call cc-option,-fstack-usage)
CFLAGS += $(CFLAGS_STACK)

# $(CPPFLAGS) sets -g, which causes gcc to pass a suitable -g<format>
# option to the assembler.
AFLAGS_DEBUG :=

AFLAGS := $(AFLAGS_DEBUG) -D__ASSEMBLY__ $(CPPFLAGS)

LDFLAGS += $(PLATFORM_LDFLAGS)
LDFLAGS_FINAL += -Bstatic

LDFLAGS_u-boot += -T $(obj)u-boot.lds $(LDFLAGS_FINAL)
ifneq ($(CONFIG_SYS_TEXT_BASE),)
LDFLAGS_u-boot += -Ttext $(CONFIG_SYS_TEXT_BASE)
endif

LDFLAGS_u-boot-spl += -T $(obj)u-boot-spl.lds $(LDFLAGS_FINAL)

#########################################################################

export	HOSTCC HOSTCFLAGS HOSTLDFLAGS PEDCFLAGS CROSS_COMPILE \
	AS LD CC CPP AR NM STRIP OBJCOPY OBJDUMP MAKE
export	CONFIG_SYS_TEXT_BASE PLATFORM_CPPFLAGS PLATFORM_RELFLAGS CPPFLAGS CFLAGS AFLAGS

#########################################################################

# Allow boards to use custom optimize flags on a per dir/file basis
BCURDIR = $(subst $(SRCTREE)/,,$(CURDIR:$(obj)%=%))
ALL_AFLAGS = $(AFLAGS) $(AFLAGS_$(BCURDIR)/$(@F)) $(AFLAGS_$(BCURDIR))
ALL_CFLAGS = $(CFLAGS) $(CFLAGS_$(BCURDIR)/$(@F)) $(CFLAGS_$(BCURDIR))
EXTRA_CPPFLAGS = $(CPPFLAGS_$(BCURDIR)/$(@F)) $(CPPFLAGS_$(BCURDIR))
ALL_CFLAGS += $(EXTRA_CPPFLAGS)

# The _DEP version uses the $< file target (for dependency generation)
# See rules.mk
EXTRA_CPPFLAGS_DEP = $(CPPFLAGS_$(BCURDIR)/$(addsuffix .o,$(basename $<))) \
		$(CPPFLAGS_$(BCURDIR))
$(obj)%.s:	%.S
	$(CPP) $(ALL_AFLAGS) -o $@ $<
$(obj)%.o:	%.S
	$(CC)  $(ALL_AFLAGS) -o $@ $< -c
$(obj)%.o:	%.c
	$(CC)  $(ALL_CFLAGS) -o $@ $< -c
$(obj)%.i:	%.c
	$(CPP) $(ALL_CFLAGS) -o $@ $< -c
$(obj)%.s:	%.c
	$(CC)  $(ALL_CFLAGS) -o $@ $< -c -S

#########################################################################

# If the list of objects to link is empty, just create an empty built-in.o
cmd_link_o_target = $(if $(strip $1),\
		      $(LD) $(LDFLAGS) -r -o $@ $1,\
		      rm -f $@; $(AR) rcs $@ )

#########################################################################
