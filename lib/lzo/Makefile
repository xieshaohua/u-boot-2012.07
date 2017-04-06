
include $(TOPDIR)/config.mk

LIB	= $(obj)liblzo.o

COBJS-$(CONFIG_LZO) += lzo1x_decompress.o

COBJS	= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
