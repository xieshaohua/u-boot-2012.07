/*
 * (C) Copyright 2002
 * Sysgo Real-Time Solutions, GmbH <www.elinos.com>
 * Marius Groeger <mgroeger@sysgo.de>
 *
 * (C) Copyright 2002, 2010
 * David Mueller, ELSOFT AG, <d.mueller@elsoft.ch>
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

#include <common.h>
#include <netdev.h>
#include <asm/io.h>
#include <asm/arch/s3c24x0_cpu.h>

DECLARE_GLOBAL_DATA_PTR;

/*
 * Miscellaneous platform dependent initialisations
 */

int board_early_init_f(void)
{
	struct s3c24x0_gpio * const gpio = s3c24x0_get_base_gpio();

	/*
	 * set up the I/O ports (JZ2440)
	 */
	writel(0x007FFFFF, &gpio->gpacon);
	writel(0x00000000, &gpio->gpbcon);
	writel(0x00000000, &gpio->gpbup);
	writel(0x00000000, &gpio->gpccon);
	writel(0x00000000, &gpio->gpcup);
	writel(0x00000000, &gpio->gpdcon);
	writel(0x00000000, &gpio->gpdup);
	writel(0x00000000, &gpio->gpecon);
	writel(0x00000000, &gpio->gpeup);
	//writel(0x00000000, &gpio->gpfcon);
	//writel(0x00000000, &gpio->gpfup);
	writel(0x00000000, &gpio->gpgcon);
	writel(0x00000000, &gpio->gpgup);
	writel(gpio->gpgdat & ((~(1<<4)) | (1<<4)), &gpio->gpgdat);
	writel(0x002AFAAA, &gpio->gphcon);
	writel(0x00000000, &gpio->gphup);
	writel(0x00000000, &gpio->gpjcon);
	writel(0x00000000, &gpio->gpjup);

	return 0;
}

int board_init(void)
{
	/* arch number of SMDK2410-Board */
	gd->bd->bi_arch_number = MACH_TYPE_SMDK2440;

	/* adress of boot parameters */
	gd->bd->bi_boot_params = 0x30000100;

	icache_enable();
	dcache_enable();

	return 0;
}

int dram_init(void)
{
	/* dram_init must store complete ramsize in gd->ram_size */
	gd->ram_size = PHYS_SDRAM_1_SIZE;
	return 0;
}

#ifdef CONFIG_CMD_NET
int board_eth_init(bd_t *bis)
{
	int rc = 0;
#ifdef CONFIG_CS8900
	rc = cs8900_initialize(0, CONFIG_CS8900_BASE);
#endif
#ifdef CONFIG_DRIVER_DM9000
	rc = dm9000_initialize(bis);
#endif
	return rc;
}
#endif

/*
 * Hardcoded flash setup:
 * Flash 0 is a non-CFI AMD AM29LV800BB flash.
 */
ulong board_flash_get_legacy(ulong base, int banknum, flash_info_t *info)
{
	info->portwidth = FLASH_CFI_16BIT;
	info->chipwidth = FLASH_CFI_BY16;
	info->interface = FLASH_CFI_X16;
	return 1;
}
