/*
 * (C) Copyright 2006 OpenMoko, Inc.
 * Author: Harald Welte <laforge@openmoko.org>
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
#define DEBUG
#include <common.h>

#include <nand.h>
#include <asm/arch/s3c24x0_cpu.h>
#include <asm/io.h>

#define S3C2440_NFCONT_EN		(1<<0)
#define S3C2440_NFCONT_nFCE        	(1<<1)		/* NFCONT[1] 0:Enable 1:Disable */

#define S3C2440_NFCONF_INITECC     	(1<<4)
#define S3C2440_NFCONT_MECCLOCK		(1<<5)
#define S3C2440_NFCONT_SECCLOCK		(1<<6)

#define S3C2440_NFCONF_TACLS(x)    	((x)<<12)
#define S3C2440_NFCONF_TWRPH0(x)   	((x)<<8)
#define S3C2440_NFCONF_TWRPH1(x)   	((x)<<4)


static int s3c2440_dev_ready(struct mtd_info *mtd)
{
	struct s3c2440_nand *nand_reg = s3c2440_get_base_nand();
	//debug("dev_ready\n");
	return !!(readl(&nand_reg->nfstat) & 0x01);
}

static void s3c2440_nand_select_chip(struct mtd_info *mtd, int chip)
{
	struct s3c2440_nand *nand_reg = s3c2440_get_base_nand();

	switch (chip) {
	case -1:
		writel(readl(&nand_reg->nfcont) | S3C2440_NFCONT_nFCE,
			&nand_reg->nfcont);
		break;
	case 0:
		writel(readl(&nand_reg->nfcont) & (~S3C2440_NFCONT_nFCE),
			&nand_reg->nfcont);
		break;
	default:
		break;
	}
}

static void s3c2440_hwcontrol(struct mtd_info *mtd, int cmd, unsigned int ctrl)
{
	struct nand_chip *this = mtd->priv;
	struct s3c2440_nand *nand_reg = s3c2440_get_base_nand();

	//debug("hwcontrol(): 0x%02x 0x%02x\n", cmd, ctrl);

	if (ctrl & NAND_CTRL_CHANGE) {
		if (ctrl & NAND_NCE)
			s3c2440_nand_select_chip(mtd, 0);
		else
			s3c2440_nand_select_chip(mtd, -1);

		if (ctrl & NAND_CLE)
			this->IO_ADDR_W = (void __iomem *)&nand_reg->nfcmd;
		else if (ctrl & NAND_ALE)
			this->IO_ADDR_W = (void __iomem *)&nand_reg->nfaddr;
		else
			this->IO_ADDR_W = (void __iomem *)&nand_reg->nfdata;
	}

	if (cmd != NAND_CMD_NONE)
		writeb(cmd, this->IO_ADDR_W);
}

#ifdef CONFIG_S3C2440_NAND_HWECC
void s3c2440_nand_enable_hwecc(struct mtd_info *mtd, int mode)
{
	u_int32_t cfg;
	struct s3c2440_nand *nand = s3c2440_get_base_nand();

	cfg = readl(&nand->nfcont);
	cfg &= ~S3C2440_NFCONT_MECCLOCK;	/* unlock */
	writel(cfg | S3C2440_NFCONF_INITECC, &nand->nfcont);

	//debug("s3c2440_nand_enable_hwecc(%p, %d)\n", mtd, mode);
}

static int s3c2440_nand_calculate_ecc(struct mtd_info *mtd, const u_char *dat,
				      u_char *ecc_code)
{
	u_int32_t nfmecc0;
	struct s3c2440_nand *nand = s3c2440_get_base_nand();

	/* Lock */
	writel(readl(&nand->nfcont) | S3C2440_NFCONT_MECCLOCK, &nand->nfcont);

	nfmecc0 = readl(&nand->nfmecc0);
	ecc_code[0] = nfmecc0 & 0xff;
	ecc_code[1] = (nfmecc0 >> 8) & 0xff;
	ecc_code[2] = (nfmecc0 >> 16) & 0xff;
	ecc_code[3] = (nfmecc0 >> 24) & 0xff;
//#ifndef CONFIG_NAND_SPL
	//debug("s3c2440_nand_calculate_hwecc(%p,): 0x%02x 0x%02x 0x%02x 0x%02x\n",
	//	mtd , ecc_code[0], ecc_code[1], ecc_code[2], ecc_code[3]);
//#endif
	return 0;
}

static int s3c2440_nand_correct_data(struct mtd_info *mtd, u_char *dat,
				     u_char *read_ecc, u_char *calc_ecc)
{
	int ret = -1;
	u_long nfestat0, nfmeccd0, nfmeccd1, err_byte_addr;
	u_char err_type, repaired;
	struct s3c2440_nand *nand = s3c2440_get_base_nand();

	/* write ecc to compare */
	nfmeccd0 = (calc_ecc[1] << 16) | calc_ecc[0];
	nfmeccd1 = (calc_ecc[3] << 16) | calc_ecc[2];
	writel(nfmeccd0, &nand->nfmeccd0);
	writel(nfmeccd1, &nand->nfmeccd1);

	/* read ecc status */
	nfestat0 = readl(&nand->nfestat0);
	err_type = nfestat0 & 0x3;

	switch (err_type) {
	case 0:	/* No error */
//#ifndef CONFIG_NAND_SPL
//		//debug("S3C2440 NAND: ECC OK!\n");
//#endif
		ret = 0;
		break;
	case 1:
		/*
		 * 1 bit error (Correctable)
		 * (nfestat0 >> 7) & 0x7ff	:error byte number
		 * (nfestat0 >> 4) & 0x7	:error bit number
		 */
		err_byte_addr = (nfestat0 >> 7) & 0x7ff;
		repaired = dat[err_byte_addr] ^ (1 << ((nfestat0 >> 4) & 0x7));
		dat[err_byte_addr] = repaired;
//#ifndef CONFIG_NAND_SPL
//		debug("S3C2440 NAND: 1 bit error detected at byte %ld. "
//		       "Correcting from 0x%02x to 0x%02x...OK\n",
//		       err_byte_addr, dat[err_byte_addr], repaired);
//#endif
		ret = 1;
		break;

	case 2: /* Multiple error */
	case 3: /* ECC area error */
	default:
//#ifndef CONFIG_NAND_SPL
//		debug("S3C2440 NAND: ECC uncorrectable error detected\n");
//#endif
		ret = -1;
		break;
	}

	return ret;
}
#endif

int board_nand_init(struct nand_chip *nand)
{
	u_int32_t cfg;
	u_int8_t tacls, twrph0, twrph1;
	struct s3c24x0_clock_power *clk_power = s3c24x0_get_base_clock_power();
	struct s3c2440_nand *nand_reg = s3c2440_get_base_nand();

	//debug("board_nand_init()\n");

	writel(readl(&clk_power->clkcon) | (1 << 4), &clk_power->clkcon);

	/* initialize hardware */
	tacls = 4;
	twrph0 = 8;
	twrph1 = 8;

	/* NAND flash controller enable */
	cfg = readl(&nand_reg->nfcont);
	cfg &= ~(1<<12);	/* disable soft lock of nand flash */
	cfg |= S3C2440_NFCONT_EN;
	writel(cfg, &nand_reg->nfcont);

	cfg = S3C2440_NFCONF_TACLS(tacls - 1);
	cfg |= S3C2440_NFCONF_TWRPH0(twrph0 - 1);
	cfg |= S3C2440_NFCONF_TWRPH1(twrph1 - 1);
	writel(readl(&nand_reg->nfconf) | cfg, &nand_reg->nfconf);

	/* initialize nand_chip data structure */
	nand->IO_ADDR_R = (void __iomem *)&nand_reg->nfdata;
	nand->IO_ADDR_W = (void __iomem *)&nand_reg->nfdata;

	nand->select_chip = s3c2440_nand_select_chip;

	/* read_buf and write_buf are default */
	/* read_byte and write_byte are default */
//#ifdef CONFIG_NAND_SPL
	nand->read_buf = nand_read_buf;
//#endif

	/* hwcontrol always must be implemented */
	nand->cmd_ctrl = s3c2440_hwcontrol;

	nand->dev_ready = s3c2440_dev_ready;

#ifdef CONFIG_S3C2440_NAND_HWECC
	nand->ecc.hwctl = s3c2440_nand_enable_hwecc;
	nand->ecc.calculate = s3c2440_nand_calculate_ecc;
	nand->ecc.correct = s3c2440_nand_correct_data;
	nand->ecc.mode = NAND_ECC_HW;
	nand->ecc.size = CONFIG_SYS_NAND_ECCSIZE;
	nand->ecc.bytes = CONFIG_SYS_NAND_ECCBYTES;
#else
	nand->ecc.mode = NAND_ECC_SOFT;
#endif

#ifdef CONFIG_S3C2440_NAND_BBT
	nand->options = NAND_USE_FLASH_BBT;
#else
	nand->options = 0;
#endif

	//debug("end of nand_init\n");

	return 0;
}
