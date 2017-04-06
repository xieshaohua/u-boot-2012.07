
include $(TOPDIR)/config.mk

LIB	= $(obj)liblzma.o

SOBJS	=

CFLAGS += -D_LZMA_PROB32

COBJS-$(CONFIG_LZMA) += LzmaDec.o LzmaTools.o

COBJS	= $(COBJS-y)
SRCS 	:= $(SOBJS:.o=.S) $(COBJS:.o=.c)
OBJS	:= $(addprefix $(obj),$(SOBJS) $(COBJS))

$(LIB):	.depend $(OBJS)
	$(call cmd_link_o_target, $(OBJS))

#########################################################################

# defines $(obj).depend target
include $(SRCTREE)/rules.mk

sinclude .depend

#########################################################################
