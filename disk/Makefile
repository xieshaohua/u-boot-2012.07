
include $(TOPDIR)/config.mk

LIB	= $(obj)libdisk.o

COBJS-$(CONFIG_PARTITIONS) 	+= part.o
COBJS-$(CONFIG_MAC_PARTITION)   += part_mac.o
COBJS-$(CONFIG_DOS_PARTITION)   += part_dos.o
COBJS-$(CONFIG_ISO_PARTITION)   += part_iso.o
COBJS-$(CONFIG_AMIGA_PARTITION) += part_amiga.o
COBJS-$(CONFIG_EFI_PARTITION)   += part_efi.o

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
