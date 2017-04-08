/*
 * (C) Copyright 2006-2008
 * Stefan Roese, DENX Software Engineering, sr@denx.de.
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
#include <nand.h>
#include <asm/io.h>

static int nand_ecc_pos[] = {40, 41, 42, 43};

#define rCLKCON     (*(volatile unsigned *)0x4c00000c)  /* Clock generator control             */

/* NAND Flash */
#define rNFCONF     (*(volatile unsigned *)0x4E000000)  /* NAND Flash configuration            */
#define rNFCONT     (*(volatile unsigned *)0x4E000004)  /* NAND Flash control                  */
#define rNFCMD      (*(volatile unsigned *)0x4E000008)  /* NAND Flash command                  */
#define rNFADDR     (*(volatile unsigned *)0x4E00000C)  /* NAND Flash address                  */
#define rNFDATA     (*(volatile unsigned *)0x4E000010)  /* NAND Flash data                     */
#define rNFMECCD0   (*(volatile unsigned *)0x4E000014)  /* NAND Flash main area ECC0/1         */
#define rNFMECCD1   (*(volatile unsigned *)0x4E000018)  /* NAND Flash main area ECC2/3         */
#define rNFSECCD    (*(volatile unsigned *)0x4E00001C)  /* NAND Flash spare area ECC           */
#define rNFSTAT     (*(volatile unsigned *)0x4E000020)  /* NAND Flash operation status         */
#define rNFESTAT0   (*(volatile unsigned *)0x4E000024)  /* NAND Flash ECC status for I/O[7:0]  */
#define rNFESTAT1   (*(volatile unsigned *)0x4E000028)  /* NAND Flash ECC status for I/O[15:0] */
#define rNFMECC0    (*(volatile unsigned *)0x4E00002C)  /* NAND Flash main area ECC0 status    */
#define rNFMECC1    (*(volatile unsigned *)0x4E000030)  /* NAND Flash main area ECC1 status    */
#define rNFSECC     (*(volatile unsigned *)0x4E000034)  /* NAND Flash spare area ECC status    */
#define rNFSBLK     (*(volatile unsigned *)0x4E000038)  /* NAND Flash start block address      */
#define rNFEBLK     (*(volatile unsigned *)0x4E00003C)  /* NAND Flash end block address        */


#define S3C2440_NFCONT_EN		(1<<0)
#define S3C2440_NFCONT_nFCE        	(1<<1)		/* NFCONT[1] 0:Enable 1:Disable */

#define S3C2440_NFCONF_INITECC     	(1<<4)
#define S3C2440_NFCONT_MECCLOCK		(1<<5)
#define S3C2440_NFCONT_SECCLOCK		(1<<6)

#define S3C2440_NFCONF_TACLS(x)    	((x)<<12)
#define S3C2440_NFCONF_TWRPH0(x)   	((x)<<8)
#define S3C2440_NFCONF_TWRPH1(x)   	((x)<<4)

static void s3c2440_nand_read_buf(struct mtd_info *mtd, uint8_t *buf, int len)
{
	int i;

	for (i = 0; i < len; i++)
		buf[i] = *((volatile unsigned char *)(&rNFDATA));
}

static int s3c2440_dev_ready(struct mtd_info *mtd)
{
	return !!(rNFSTAT & 0x01);
}

static void s3c2440_nand_select_chip(struct mtd_info *mtd, int chip)
{
	switch (chip) {
	case -1:
		rNFCONT |= S3C2440_NFCONT_nFCE;
		break;
	case 0:
		rNFCONT &= ~S3C2440_NFCONT_nFCE;
		break;
	default:
		break;
	}
}

static void s3c2440_hwcontrol(struct mtd_info *mtd, int cmd, unsigned int ctrl)
{
	if (ctrl & NAND_NCE)
		s3c2440_nand_select_chip(mtd, 0);
	else
		s3c2440_nand_select_chip(mtd, -1);

	if (cmd != NAND_CMD_NONE) {
		if (ctrl & NAND_CLE)
			rNFCMD = cmd;
		else if (ctrl & NAND_ALE)
			rNFADDR = cmd;
		else
			rNFDATA = cmd;
	}
}

#ifdef CONFIG_S3C2440_NAND_HWECC
void s3c2440_nand_enable_hwecc(struct mtd_info *mtd, int mode)
{
	unsigned long cfg = rNFCONT;

	cfg &= ~S3C2440_NFCONT_MECCLOCK;	/* unlock */
	rNFCONT = cfg | S3C2440_NFCONF_INITECC;
}

static int s3c2440_nand_calculate_ecc(struct mtd_info *mtd, const u_char *dat,
				      u_char *ecc_code)
{
	unsigned long nfmecc0;

	/* Lock */
	rNFCONT |= S3C2440_NFCONT_MECCLOCK;

	nfmecc0 = rNFMECCD0;
	ecc_code[0] = nfmecc0 & 0xff;
	ecc_code[1] = (nfmecc0 >> 8) & 0xff;
	ecc_code[2] = (nfmecc0 >> 16) & 0xff;
	ecc_code[3] = (nfmecc0 >> 24) & 0xff;

	return 0;
}

static int s3c2440_nand_correct_data(struct mtd_info *mtd, u_char *dat,
				     u_char *read_ecc, u_char *calc_ecc)
{
	int ret = -1;
	unsigned long nfestat0, nfmeccd0, nfmeccd1, err_byte_addr;
	unsigned char err_type, repaired;

	/* write ecc to compare */
	nfmeccd0 = (calc_ecc[1] << 16) | calc_ecc[0];
	nfmeccd1 = (calc_ecc[3] << 16) | calc_ecc[2];
	rNFMECCD0 = nfmeccd0;
	rNFMECCD1 = nfmeccd1;

	/* read ecc status */
	nfestat0 = rNFESTAT0;
	err_type = nfestat0 & 0x3;

	switch (err_type) {
	case 0:	/* No error */
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
		ret = 1;
		break;

	case 2: /* Multiple error */
	case 3: /* ECC area error */
	default:
		ret = -1;
		break;
	}

	return ret;
}
#endif

int board_nand_init(struct nand_chip *nand)
{
	unsigned long cfg;
	u_int8_t tacls, twrph0, twrph1;

	rCLKCON |= (1 << 4);

	/* initialize hardware */
	tacls = 4;
	twrph0 = 8;
	twrph1 = 8;

	/* NAND flash controller enable */
	cfg = rNFCONT;
	cfg &= ~(1<<12);	/* disable soft lock of nand flash */
	cfg |= S3C2440_NFCONT_EN;
	rNFCONT = cfg;

	cfg = S3C2440_NFCONF_TACLS(tacls - 1);
	cfg |= S3C2440_NFCONF_TWRPH0(twrph0 - 1);
	cfg |= S3C2440_NFCONF_TWRPH1(twrph1 - 1);
	rNFCONF = cfg;

	/* initialize nand_chip data structure */
	nand->IO_ADDR_R = (void __iomem *)&rNFDATA;
	nand->IO_ADDR_W = (void __iomem *)&rNFDATA;

	nand->select_chip = s3c2440_nand_select_chip;

	/* read_buf and write_buf are default */
	/* read_byte and write_byte are default */
	nand->read_buf = s3c2440_nand_read_buf;

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

	nand->options = 0;

	return 0;
}

/*
 * NAND command for large page NAND devices (2k)
 */
static int nand_command(struct mtd_info *mtd, int block, int page, int offs, u8 cmd)
{
	struct nand_chip *this = mtd->priv;
	int page_addr = page + block * CONFIG_SYS_NAND_PAGE_COUNT;
	void (*hwctrl)(struct mtd_info *mtd, int cmd,
			unsigned int ctrl) = this->cmd_ctrl;

	while (!this->dev_ready(mtd))
		;

	/* Emulate NAND_CMD_READOOB */
	if (cmd == NAND_CMD_READOOB) {
		offs += CONFIG_SYS_NAND_PAGE_SIZE;
		cmd = NAND_CMD_READ0;
	}

	/* Begin command latch cycle */
	hwctrl(mtd, cmd, NAND_CTRL_CLE | NAND_CTRL_CHANGE);
	/* Set ALE and clear CLE to start address cycle */
	/* Column address */
	hwctrl(mtd, offs & 0xff,
		       NAND_CTRL_ALE | NAND_CTRL_CHANGE); /* A[7:0] */
	hwctrl(mtd, (offs >> 8) & 0xff, NAND_CTRL_ALE); /* A[11:9] */
	/* Row address */
	hwctrl(mtd, (page_addr & 0xff), NAND_CTRL_ALE); /* A[19:12] */
	hwctrl(mtd, ((page_addr >> 8) & 0xff),
		       NAND_CTRL_ALE); /* A[27:20] */
	hwctrl(mtd, (page_addr >> 16) & 0x0f,
		       NAND_CTRL_ALE); /* A[31:28] */

	/* Latch in address */
	hwctrl(mtd, NAND_CMD_READSTART,
		       NAND_CTRL_CLE | NAND_CTRL_CHANGE);
	hwctrl(mtd, NAND_CMD_NONE, NAND_NCE | NAND_CTRL_CHANGE);

	/*
	 * Wait a while for the data to be ready
	 */
	while (!this->dev_ready(mtd))
		;

	return 0;
}

static int nand_is_bad_block(struct mtd_info *mtd, int block)
{
	struct nand_chip *this = mtd->priv;

	nand_command(mtd, block, 0, CONFIG_SYS_NAND_BAD_BLOCK_POS, NAND_CMD_READOOB);

	/*
	 * Read one byte (or two if it's a 16 bit chip).
	 */

	if (readb(this->IO_ADDR_R) != 0xff)
		return 1;
	else
		return 0;
}

static int nand_read_page(struct mtd_info *mtd, int block, int page, uchar *dst)
{
	struct nand_chip *this = mtd->priv;
	u_char ecc_calc[4];
	u_char ecc_code[4];
	u_char oob_data[64];
	int i;
	int eccsize = 2048;
	int eccbytes = 4;
	uint8_t *p = dst;

	nand_command(mtd, block, page, 0, NAND_CMD_READ0);

	this->ecc.hwctl(mtd, NAND_ECC_READ);
	this->read_buf(mtd, p, 2048);
	this->ecc.calculate(mtd, p, &ecc_calc[0]);

	this->read_buf(mtd, oob_data, 64);

	/* Pick the ECC bytes out of the oob data */
	for (i = 0; i < 4; i++)
		ecc_code[i] = oob_data[nand_ecc_pos[i]];

	/* No chance to do something with the possible error message
	 * from correct_data(). We just hope that all possible errors
	 * are corrected by this routine.
	 */
	//this->ecc.correct(mtd, p, &ecc_code[i], &ecc_calc[i]);

	return 0;
}

static int nand_load(struct mtd_info *mtd, unsigned int offs,
		     unsigned int uboot_size, uchar *dst)
{
	unsigned int block, lastblock;
	unsigned int page;

	/*
	 * offs has to be aligned to a page address!
	 */
	block = offs / CONFIG_SYS_NAND_BLOCK_SIZE;
	lastblock = (offs + uboot_size - 1) / CONFIG_SYS_NAND_BLOCK_SIZE;
	page = (offs % CONFIG_SYS_NAND_BLOCK_SIZE) / CONFIG_SYS_NAND_PAGE_SIZE;

	while (block <= lastblock) {
		if (!nand_is_bad_block(mtd, block)) {
			/*
			 * Skip bad blocks
			 */
			while (page < CONFIG_SYS_NAND_PAGE_COUNT) {
				nand_read_page(mtd, block, page, dst);
				dst += CONFIG_SYS_NAND_PAGE_SIZE;
				page++;
			}

			page = 0;
		} else {
			lastblock++;
		}

		block++;
	}

	return 0;
}

/*
 * The main entry for NAND booting. It's necessary that SDRAM is already
 * configured and available since this code loads the main U-Boot image
 * from NAND into SDRAM and starts it from there.
 */
void nand_boot(void)
{
	struct nand_chip nand_chip;
	nand_info_t nand_info;
	__attribute__((noreturn)) void (*uboot)(void);

	/*
	 * Init board specific nand support
	 */
	nand_chip.select_chip = NULL;
	nand_info.priv = &nand_chip;
	nand_chip.IO_ADDR_R = nand_chip.IO_ADDR_W = (void  __iomem *)CONFIG_SYS_NAND_BASE;
	nand_chip.dev_ready = NULL;	/* preset to NULL */
	nand_chip.options = 0;
	board_nand_init(&nand_chip);

	if (nand_chip.select_chip)
		nand_chip.select_chip(&nand_info, 0);

	/*
	 * Load U-Boot image from NAND into RAM
	 */
	nand_load(&nand_info, CONFIG_SYS_NAND_U_BOOT_OFFS, CONFIG_SYS_NAND_U_BOOT_SIZE,
		  (uchar *)CONFIG_SYS_NAND_BOOT_START);

	if (nand_chip.select_chip)
		nand_chip.select_chip(&nand_info, -1);

	/*
	 * Jump to U-Boot image
	 */
	uboot = (void *)CONFIG_SYS_NAND_BOOT_START;
	(*uboot)();
}
