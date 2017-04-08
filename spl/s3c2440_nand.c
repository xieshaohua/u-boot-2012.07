#include <common.h>

#include <nand.h>
#include <asm/io.h>


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
