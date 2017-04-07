
CROSS_COMPILE ?= arm-linux-

CC	= $(CROSS_COMPILE)gcc
LD	= $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

PLATFORM_CPPFLAGS += -DCONFIG_ARM -D__ARM__ -marm -mno-thumb-interwork -mabi=aapcs-linux -march=armv4

CONFIG_SYS_TEXT_BASE = 0

#########################################################################

gccincdir := $(shell $(CC) -print-file-name=include)

CPPFLAGS := -g -Os -fno-common -ffixed-r8 -msoft-float -D__KERNEL__ -DCONFIG_SYS_TEXT_BASE=$(CONFIG_SYS_TEXT_BASE)	\
			-I../include -fno-builtin -ffreestanding -nostdinc -isystem $(gccincdir) -pipe $(PLATFORM_CPPFLAGS)

CFLAGS := $(CPPFLAGS) -Wall -Wstrict-prototypes -fno-stack-protector -Wno-format-nonliteral -Wno-format-security


AFLAGS := -D__ASSEMBLY__ $(CPPFLAGS)

#########################################################################

LDSCRIPT= spl.lds
LDFLAGS := -T $(LDSCRIPT) -Ttext $(CONFIG_SYS_TEXT_BASE) $(LDFLAGS) -Bstatic -gc-sections
AFLAGS	+= -DCONFIG_NAND_SPL
CFLAGS	+= -DCONFIG_NAND_SPL -ffunction-sections

SOBJS	= start.o lowlevel_init.o
COBJS	= nand_boot.o s3c2440_nand.o smdk2440_nand_spl.o nand_base.o

OBJS	:= $(SOBJS) $(COBJS)

all:	spl spl.bin spl-4k.bin

spl-4k.bin:	spl
	$(OBJCOPY) --gap-fill=0xff --pad-to=4096 -O binary $< $@

spl.bin:	spl
	$(OBJCOPY) --gap-fill=0xff -O binary $< $@

spl:	$(OBJS) $(LDSCRIPT)
	$(LD) $(LDFLAGS) $(OBJS) -Map spl.map -o spl

#########################################################################

%.o:	%.S
	$(CC) $(AFLAGS) -c -o $@ $<
%.o:	%.c
	$(CC) $(CFLAGS) -c -o $@ $<

#########################################################################
clean:
	@rm -f *.o *.map
	@rm -f spl spl.bin spl-4k.bin
