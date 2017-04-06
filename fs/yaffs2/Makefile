include $(TOPDIR)/config.mk

LIB = libyaffs2.o

COBJS-$(CONFIG_YAFFS2) := \
	yaffscfg.o yaffs_ecc.o yaffsfs.o yaffs_guts.o yaffs_packedtags1.o \
	yaffs_tagscompat.o yaffs_packedtags2.o yaffs_tagsvalidity.o \
	yaffs_nand.o yaffs_checkptrw.o yaffs_qsort.o yaffs_mtdif.o \
	yaffs_mtdif2.o

COBJS    := $(COBJS-y)

# -DCONFIG_YAFFS_NO_YAFFS1
CFLAGS +=    -DCONFIG_YAFFS_DIRECT -DCONFIG_YAFFS_SHORT_NAMES_IN_RAM -DCONFIG_YAFFS_YAFFS2 -DLINUX_VERSION_CODE=0x20622

$(LIB): $(COBJS)
	$(call cmd_link_o_target, $(COBJS))

#########################################################################

#include $(SRCTREE)/rules.mk

#sinclude .depend

#########################################################################
