#
# (C) Copyright 2002
# Gary Jennejohn, DENX Software Engineering, <garyj@denx.de>
# David Mueller, ELSOFT AG, <d.mueller@elsoft.ch>
#
# (C) Copyright 2008
# Guennadi Liakhovetki, DENX Software Engineering, <lg@denx.de>
#
# SAMSUNG SMDK2440 board with mDirac3 (ARM920t) cpu
#
# see http://www.samsung.com/ for more information on SAMSUNG

# On SMDK2440 we use the 64 MB SDRAM bank at
#
# 0x50000000 to 0x58000000
#
# Linux-Kernel is expected to be at 0x50008000, entry 0x50008000
#
# we load ourselves to 0x57e00000 without MMU
# with MMU, load address is changed to 0xc7e00000
#
# download area is 0x5000c000

ifndef CONFIG_NAND_SPL
CONFIG_SYS_TEXT_BASE = 0x32000000
#CONFIG_SYS_TEXT_BASE = 0
else
CONFIG_SYS_TEXT_BASE = 0
endif