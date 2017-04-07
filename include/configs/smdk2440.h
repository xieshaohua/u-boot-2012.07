/*
 * (C) Copyright 2002
 * Sysgo Real-Time Solutions, GmbH <www.elinos.com>
 * Marius Groeger <mgroeger@sysgo.de>
 * Gary Jennejohn <garyj@denx.de>
 * David Mueller <d.mueller@elsoft.ch>
 *
 * Configuation settings for the SAMSUNG SMDK2410 board.
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#ifndef __CONFIG_H
#define __CONFIG_H

/*
 * High Level Configuration Options
 * (easy to change)
 */
#define CONFIG_ARM920T		/* This is an ARM920T Core */
#define CONFIG_S3C24X0		/* in a SAMSUNG S3C24x0-type SoC */
#define CONFIG_S3C2440		/* specifically a SAMSUNG S3C2410 SoC */
#define CONFIG_SMDK2440		/* on a SAMSUNG SMDK2410 Board */

//#define CONFIG_SYS_TEXT_BASE	0x0

#define CONFIG_SYS_ARM_CACHE_WRITETHROUGH

/* input clock of PLL (the SMDK2410 has 12MHz input clock) */
#define CONFIG_SYS_CLK_FREQ	12000000

#undef CONFIG_USE_IRQ		/* we don't need IRQ/FIQ stuff */

#define CONFIG_CMDLINE_TAG	/* enable passing of ATAGs */
#define CONFIG_SETUP_MEMORY_TAGS
#define CONFIG_INITRD_TAG

/*
 * Hardware drivers
 */
#define CONFIG_DRIVER_DM9000		/* we have a DM9000 on-board */
#define CONFIG_DM9000_NO_SROM
#define CONFIG_DM9000_BASE		0x20000000
#define DM9000_IO			CONFIG_DM9000_BASE
#define DM9000_DATA			(CONFIG_DM9000_BASE + 4)

/*
 * select serial console configuration
 */
#define CONFIG_S3C24X0_SERIAL
#define CONFIG_SERIAL1		1	/* we use SERIAL 1 on SMDK2410 */

/************************************************************
 * RTC
 ************************************************************/
#define CONFIG_RTC_S3C24X0


#define CONFIG_BAUDRATE		115200

/*
 * BOOTP options
 */
#define CONFIG_BOOTP_BOOTFILESIZE
#define CONFIG_BOOTP_BOOTPATH
#define CONFIG_BOOTP_GATEWAY
#define CONFIG_BOOTP_HOSTNAME

/*
 * Command line configuration.
 */
#include <config_cmd_default.h>

#define CONFIG_CMD_BSP
#define CONFIG_CMD_CACHE
#define CONFIG_CMD_DATE
#define CONFIG_CMD_DHCP
#define CONFIG_CMD_ELF
#define CONFIG_CMD_NAND
#define CONFIG_CMD_PING
#define CONFIG_CMD_REGINFO

#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_CMDLINE_EDITING

/* autoboot */
#define CONFIG_BOOTDELAY	3
#define CONFIG_BOOT_RETRY_TIME	-1
#define CONFIG_RESET_TO_RETRY
#define CONFIG_ZERO_BOOTDELAY_CHECK

#define CONFIG_NETMASK		255.255.255.0
#define CONFIG_IPADDR		192.168.11.5
#define CONFIG_SERVERIP		192.168.11.2
#define CONFIG_ETHADDR		08:00:3e:26:0a:5b

#if defined(CONFIG_CMD_KGDB)
#define CONFIG_KGDB_BAUDRATE	115200	/* speed to run kgdb serial port */
/* what's this ? it's not used anywhere */
#define CONFIG_KGDB_SER_INDEX	2	/* which serial port to use */
#endif

/*
 * Miscellaneous configurable options
 */
#define CONFIG_SYS_LONGHELP		/* undef to save memory */
#define CONFIG_SYS_PROMPT	"SMDK2440 # "
#define CONFIG_SYS_CBSIZE	256
/* Print Buffer Size */
#define CONFIG_SYS_PBSIZE	(CONFIG_SYS_CBSIZE + \
				sizeof(CONFIG_SYS_PROMPT)+16)
#define CONFIG_SYS_MAXARGS	16
#define CONFIG_SYS_BARGSIZE	CONFIG_SYS_CBSIZE

#define CONFIG_DISPLAY_CPUINFO				/* Display cpu info */

#define CONFIG_SYS_MEMTEST_START	0x30000000	/* memtest works on */
#define CONFIG_SYS_MEMTEST_END		0x33F00000	/* 63 MB in DRAM */

#define CONFIG_SYS_LOAD_ADDR		0x30800000

#define CONFIG_SYS_HZ			1000

/* support additional compression methods */
#define CONFIG_BZIP2
#define CONFIG_LZO
#define CONFIG_LZMA

/*-----------------------------------------------------------------------
 * Stack sizes
 *
 * The stack sizes are set up in start.S using the settings below
 */
#define CONFIG_STACKSIZE	(4*1024)	/* stack for nand spl */
#ifdef CONFIG_USE_IRQ
#define CONFIG_STACKSIZE_IRQ	(4*1024)	/* IRQ stack */
#define CONFIG_STACKSIZE_FIQ	(4*1024)	/* FIQ stack */
#endif

/*-----------------------------------------------------------------------
 * Physical Memory Map
 */
#define CONFIG_NR_DRAM_BANKS	1          /* we have 1 bank of DRAM */
#define PHYS_SDRAM_1		0x30000000 /* SDRAM Bank #1 */
#define PHYS_SDRAM_1_SIZE	0x04000000 /* 64 MB */

#define PHYS_FLASH_1		0x00000000 /* Flash Bank #0 */

#define CONFIG_SYS_FLASH_BASE	PHYS_FLASH_1

/*-----------------------------------------------------------------------
 * FLASH and environment organization
 */

#define CONFIG_SYS_FLASH_CFI
#define CONFIG_FLASH_CFI_DRIVER
#define CONFIG_FLASH_CFI_LEGACY
#define CONFIG_SYS_FLASH_LEGACY_1Mx16
#define CONFIG_FLASH_SHOW_PROGRESS	45

#define CONFIG_SYS_MAX_FLASH_BANKS	1
#define CONFIG_SYS_FLASH_BANKS_LIST     { CONFIG_SYS_FLASH_BASE }
#define CONFIG_SYS_MAX_FLASH_SECT	(64)

#define CONFIG_ENV_OFFSET		(0x80000)
#define CONFIG_ENV_IS_IN_NAND
#define CONFIG_ENV_SIZE			(0x20000)
/* allow to overwrite serial and ethaddr */
#define CONFIG_ENV_OVERWRITE

/*
 * Size of malloc() pool
 * BZIP2 / LZO / LZMA need a lot of RAM
 */
#define CONFIG_SYS_MALLOC_LEN	(4 * 1024 * 1024)

#define CONFIG_SYS_MONITOR_LEN	(448 * 1024)
#define CONFIG_SYS_MONITOR_BASE	CONFIG_SYS_FLASH_BASE

/*
 * NAND configuration
 */
#ifdef CONFIG_CMD_NAND
#define CONFIG_NAND_S3C2440
#define CONFIG_S3C2440_NAND_HWECC
#define CONFIG_SYS_MAX_NAND_DEVICE	1
#define CONFIG_SYS_NAND_BASE		0x4E000000
#define CONFIG_SYS_NAND_PAGE_SIZE	2048		/* NAND chip page size		*/
#define CONFIG_SYS_NAND_ECCSIZE		CONFIG_SYS_NAND_PAGE_SIZE
/* Number of ECC bytes per OOB - S3C2440 calculates 4 bytes ECC in 1-bit mode */
#define CONFIG_SYS_NAND_ECCBYTES	4
#define CONFIG_NAND_U_BOOT
#ifdef CONFIG_NAND_U_BOOT
/* NAND configuration */
#define CONFIG_SYS_NAND_BOOT_START	0x33F00000

#define CONFIG_SYS_NAND_U_BOOT_OFFS	(4 * 1024)	/* Offset to RAM U-Boot image */
#define CONFIG_SYS_NAND_U_BOOT_SIZE	(512 * 1024)	/* Size of RAM U-Boot image   */

/* NAND chip block size		*/
#define CONFIG_SYS_NAND_BLOCK_SIZE	(128 * 1024)
/* NAND chip page per block count  */
#define CONFIG_SYS_NAND_PAGE_COUNT	64
/* Location of the bad-block label */
#define CONFIG_SYS_NAND_BAD_BLOCK_POS	0
/* Extra address cycle for > 128MiB */
#define CONFIG_SYS_NAND_5_ADDR_CYCLE
/* Size of a single OOB region */
#define CONFIG_SYS_NAND_OOBSIZE		64
/* ECC byte positions */
#define CONFIG_SYS_NAND_ECCPOS		{40, 41, 42, 43, 44, 45, 46, 47, \
				 	 48, 49, 50, 51, 52, 53, 54, 55, \
				 	 56, 57, 58, 59, 60, 61, 62, 63}
#endif
#endif	/* CONFIG_CMD_NAND */

/*
 * File system
 */
#define CONFIG_CMD_MTDPARTS
#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_YAFFS2

#define CONFIG_CMD_NAND_YAFFS

/* additions for new relocation code, must be added to all boards */
#define CONFIG_SYS_SDRAM_BASE	PHYS_SDRAM_1
#define CONFIG_SYS_INIT_SP_ADDR	(CONFIG_SYS_NAND_BOOT_START - GENERATED_GBL_DATA_SIZE)

#define CONFIG_BOARD_EARLY_INIT_F

#define MTDIDS_DEFAULT			"nand0=nandflash0"
#define MTDPARTS_DEFAULT		"mtdparts=nandflash0:512k@0(u-boot)," \
                           		"128k(params)," \
                           		"4m(kernel)," \
                           		"-(rootfs)"

#define CONFIG_BOOTARGS			"noinitrd root=/dev/mtdblock3 rootfstype=yaffs2 rw init=/linuxrc console=ttySAC0,115200"
#define CONFIG_BOOTCOMMAND		"nand read 30008000 kernel;bootm 30008000"


#endif /* __CONFIG_H */
