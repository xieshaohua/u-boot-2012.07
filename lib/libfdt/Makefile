
include $(TOPDIR)/config.mk

LIB	= $(obj)libfdt.o

COBJS-libfdt += fdt.o fdt_ro.o fdt_rw.o fdt_strerror.o fdt_sw.o fdt_wip.o

COBJS-$(CONFIG_OF_LIBFDT) += $(COBJS-libfdt)
COBJS-$(CONFIG_FIT) += $(COBJS-libfdt)


COBJS	:= $(sort $(COBJS-y))

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))

#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

#########################################################################
