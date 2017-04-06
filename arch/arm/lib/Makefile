
include $(TOPDIR)/config.mk

LIB	= lib$(ARCH).o

COBJS-y	+= board.o
COBJS-y	+= bootm.o
COBJS-y	+= interrupts.o
COBJS-y	+= reset.o
SOBJS-$(CONFIG_USE_ARCH_MEMSET) += memset.o
SOBJS-$(CONFIG_USE_ARCH_MEMCPY) += memcpy.o
COBJS-y	+= cache.o
COBJS-y	+= cache-cp15.o

OBJS	:= $(SOBJS-y) $(COBJS-y)

# Always build libarm.o
TARGETS	:= $(LIB)

# For EABI conformant tool chains, provide eabi_compat()
TARGETS	+= eabi_compat.o

all:	$(TARGETS)

$(LIB): $(OBJS)
	$(call cmd_link_o_target, $(OBJS))
