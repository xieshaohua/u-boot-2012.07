
include $(TOPDIR)/config.mk

LIB	= $(obj)libz.o

COBJS-$(CONFIG_ZLIB) += zlib.o

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))

#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

#########################################################################
