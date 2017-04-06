
include $(TOPDIR)/config.mk

LIB	:= $(obj)libnand.o

ifdef CONFIG_CMD_NAND
COBJS-y += nand.o
COBJS-y += nand_bbt.o
COBJS-y += nand_ids.o
COBJS-y += nand_util.o
COBJS-y += nand_ecc.o
COBJS-y += nand_base.o

COBJS-$(CONFIG_NAND_S3C2440) += s3c2440_nand.o
endif

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
