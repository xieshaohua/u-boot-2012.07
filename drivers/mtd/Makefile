
include $(TOPDIR)/config.mk

LIB	:= $(obj)libmtd.o

COBJS-$(CONFIG_MTD_DEVICE) += mtdcore.o
COBJS-$(CONFIG_MTD_PARTITIONS) += mtdpart.o
COBJS-$(CONFIG_MTD_CONCAT) += mtdconcat.o
COBJS-$(CONFIG_HAS_DATAFLASH) += at45.o
COBJS-$(CONFIG_FLASH_CFI_DRIVER) += cfi_flash.o
COBJS-$(CONFIG_FLASH_CFI_MTD) += cfi_mtd.o
COBJS-$(CONFIG_HAS_DATAFLASH) += dataflash.o
COBJS-$(CONFIG_FTSMC020) += ftsmc020.o
COBJS-$(CONFIG_FLASH_CFI_LEGACY) += jedec_flash.o
COBJS-$(CONFIG_MW_EEPROM) += mw_eeprom.o
COBJS-$(CONFIG_ST_SMI) += st_smi.o

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
