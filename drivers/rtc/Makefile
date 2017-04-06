
include $(TOPDIR)/config.mk

LIB	= $(obj)librtc.o

COBJS-y += date.o
COBJS-$(CONFIG_RTC_S3C24X0) += s3c24x0_rtc.o

COBJS	:= $(sort $(COBJS-y))

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
