
include $(TOPDIR)/config.mk

LIB	= lib$(SOC).o

COBJS-$(CONFIG_USE_IRQ) += interrupts.o
COBJS-$(CONFIG_DISPLAY_CPUINFO)	+= cpu_info.o
COBJS-y	+= speed.o
COBJS-y	+= timer.o
#COBJS-y	+= usb.o
#COBJS-y	+= usb_ohci.o

COBJS	:= $(COBJS-y)

$(LIB):	$(COBJS)
	$(call cmd_link_o_target, $(COBJS))
