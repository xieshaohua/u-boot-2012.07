
include $(TOPDIR)/config.mk

LIB	= lib$(CPU).o

START	= start.o lowlevel_init.o nand_boot.o

COBJS-y	+= cpu.o
COBJS-$(CONFIG_USE_IRQ)	+= interrupts.o

COBJS	:= $(COBJS-y)

all:	$(START) $(LIB)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
