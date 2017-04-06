
include $(TOPDIR)/config.mk

LIB	:= libserial.o

COBJS-$(CONFIG_S3C24X0_SERIAL) += serial_s3c24x0.o

COBJS-$(CONFIG_USB_TTY) += usbtty.o

COBJS	:= $(sort $(COBJS-y))

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))

#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

#########################################################################
