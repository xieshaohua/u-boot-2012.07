
include $(TOPDIR)/config.mk

LIB 	:= libubi.o

ifdef CONFIG_CMD_UBI
COBJS-y += build.o vtbl.o vmt.o upd.o kapi.o eba.o io.o wl.o scan.o crc32.o

COBJS-y += misc.o
COBJS-y += debug.o
endif

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))

#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

#########################################################################
