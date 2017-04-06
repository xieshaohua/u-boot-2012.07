
include $(TOPDIR)/config.mk

LIB	= libjffs2.o

ifdef CONFIG_CMD_JFFS2
COBJS-$(CONFIG_JFFS2_LZO) += compr_lzo.o
COBJS-y += compr_rtime.o
COBJS-y += compr_rubin.o
COBJS-y += compr_zlib.o
COBJS-y += jffs2_1pass.o
COBJS-y += mini_inflate.o
endif

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))


#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude .depend

#########################################################################
