
include $(TOPDIR)/config.mk

LIB	= $(obj)liblzma.o

CFLAGS += -D_LZMA_PROB32

COBJS-$(CONFIG_LZMA) += LzmaDec.o LzmaTools.o

COBJS	= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
