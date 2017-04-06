
subdirs-$(CONFIG_CMD_JFFS2) += jffs2
subdirs-$(CONFIG_YAFFS2) += yaffs2

SUBDIRS	:= $(subdirs-y)

all:
	@for dir in $(SUBDIRS) ; do $(MAKE) -C $$dir $@ ; done
