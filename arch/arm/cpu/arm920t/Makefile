
include $(TOPDIR)/config.mk

LIB	= lib$(CPU).o

START	= start.o

COBJS-y	+= cpu.o
COBJS-$(CONFIG_USE_IRQ)	+= interrupts.o

COBJS	:= $(COBJS-y)

all:	$(START) $(LIB)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))

#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

#########################################################################
