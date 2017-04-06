
CONFIG_NAND_SPL	= y

include $(TOPDIR)/config.mk

splobj	:= $(OBJTREE)/spl/

LDSCRIPT= $(splobj)spl.lds
LDFLAGS := -T $(LDSCRIPT) -Ttext $(CONFIG_SYS_TEXT_BASE) $(LDFLAGS) \
		$(LDFLAGS_FINAL) -gc-sections
AFLAGS	+= -DCONFIG_NAND_SPL
CFLAGS	+= -DCONFIG_NAND_SPL -ffunction-sections

SOBJS	= start.o lowlevel_init.o
COBJS	= nand_boot.o s3c2440_nand.o smdk2440_nand_spl.o nand_base.o

SRCS	:= $(addprefix $(obj),$(SOBJS:.o=.S) $(COBJS:.o=.c))
OBJS	:= $(addprefix $(obj),$(SOBJS) $(COBJS))
__OBJS	:= $(SOBJS) $(COBJS)

ALL	= $(splobj)spl $(splobj)spl.bin $(splobj)spl-4k.bin

all:	$(ALL)

$(splobj)spl-4k.bin: $(splobj)spl
	$(OBJCOPY) ${OBJCFLAGS} --pad-to=4096 -O binary $< $@

$(splobj)spl.bin:	$(splobj)spl
	$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

$(splobj)spl:	$(OBJS) $(LDSCRIPT)
	cd $(splobj) && $(LD) $(LDFLAGS) $(__OBJS) \
		-Map $(splobj)spl.map \
		-o $(splobj)spl

#########################################################################

%.o:	%.S
	$(CC) $(AFLAGS) -c -o $@ $<

%.o:	%.c
	$(CC) $(CFLAGS) -c -o $@ $<

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

#########################################################################
