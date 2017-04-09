
/* Select the chip by setting nCE to low */
#define NAND_NCE		0x01
/* Select the command latch by setting CLE to high */
#define NAND_CLE		0x02
/* Select the address latch by setting ALE to high */
#define NAND_ALE		0x04

#define NAND_CTRL_CLE		(NAND_NCE | NAND_CLE)
#define NAND_CTRL_ALE		(NAND_NCE | NAND_ALE)

/*
 * Standard NAND flash commands
 */
#define NAND_CMD_READ0		0
#define NAND_CMD_READOOB	0x50

#define NAND_CMD_NONE		-1

/* Extended commands for large page devices */
#define NAND_CMD_READSTART	0x30

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
/* Size of a single OOB region */
#define CONFIG_SYS_NAND_OOBSIZE		64
#define CONFIG_SYS_NAND_PAGE_SIZE	2048		/* NAND chip page size		*/


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

static void s3c2440_nand_read_buf(unsigned char *buf, int len)
{
	int i;

	for (i = 0; i < len; i++)
		buf[i] = *((volatile unsigned char *)(&rNFDATA));
}

static int s3c2440_dev_ready(void)
{
	return !!(rNFSTAT & 0x01);
}

static void s3c2440_nand_select_chip(int chip)
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

static void s3c2440_hwcontrol(int cmd, unsigned int ctrl)
{
	if (ctrl & NAND_NCE)
		s3c2440_nand_select_chip(0);
	else
		s3c2440_nand_select_chip(-1);

	if (cmd != NAND_CMD_NONE) {
		if (ctrl & NAND_CLE)
			rNFCMD = cmd;
		else if (ctrl & NAND_ALE)
			rNFADDR = cmd;
		else
			rNFDATA = cmd;
	}
}

void s3c2440_nand_enable_hwecc(void)
{
	unsigned long cfg = rNFCONT;

	cfg &= ~S3C2440_NFCONT_MECCLOCK;	/* unlock */
	rNFCONT = cfg | S3C2440_NFCONF_INITECC;
}

static int s3c2440_nand_calculate_ecc(unsigned char *ecc_code)
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

static int s3c2440_nand_correct_data(unsigned char *dat,
				     unsigned char *read_ecc, unsigned char *calc_ecc)
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

int board_nand_init(void)
{
	unsigned long cfg;
	unsigned char tacls, twrph0, twrph1;

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

	return 0;
}

/*
 * NAND command for large page NAND devices (2k)
 */
static int nand_command(int block, int page, int offs, unsigned char cmd)
{
	int page_addr = page + block * CONFIG_SYS_NAND_PAGE_COUNT;

	while (!s3c2440_dev_ready());

	/* Emulate NAND_CMD_READOOB */
	if (cmd == NAND_CMD_READOOB) {
		offs += CONFIG_SYS_NAND_PAGE_SIZE;
		cmd = NAND_CMD_READ0;
	}

	/* Begin command latch cycle */
	s3c2440_hwcontrol(cmd, NAND_CTRL_CLE);
	/* Set ALE and clear CLE to start address cycle */
	/* Column address */
	s3c2440_hwcontrol(offs & 0xff, NAND_CTRL_ALE); /* A[7:0] */
	s3c2440_hwcontrol((offs >> 8) & 0xff, NAND_CTRL_ALE); /* A[11:9] */
	/* Row address */
	s3c2440_hwcontrol((page_addr & 0xff), NAND_CTRL_ALE); /* A[19:12] */
	s3c2440_hwcontrol(((page_addr >> 8) & 0xff),
		       NAND_CTRL_ALE); /* A[27:20] */
	s3c2440_hwcontrol((page_addr >> 16) & 0x0f,
		       NAND_CTRL_ALE); /* A[31:28] */

	/* Latch in address */
	s3c2440_hwcontrol(NAND_CMD_READSTART, NAND_CTRL_CLE);
	s3c2440_hwcontrol(NAND_CMD_NONE, NAND_NCE);

	/*
	 * Wait a while for the data to be ready
	 */
	while (!s3c2440_dev_ready());

	return 0;
}

static int nand_is_bad_block(int block)
{
	nand_command(block, 0, CONFIG_SYS_NAND_BAD_BLOCK_POS, NAND_CMD_READOOB);

	/*
	 * Read one byte (or two if it's a 16 bit chip).
	 */

	if (*((volatile unsigned char *)(&rNFDATA)) != 0xff)
		return 1;
	else
		return 0;
}

static int nand_read_page(int block, int page, unsigned char *dst)
{
	unsigned char ecc_calc[4];
	unsigned char ecc_code[4];
	unsigned char oob_data[64];
	int i;
	int eccsize = 2048;
	int eccbytes = 4;
	unsigned char *p = dst;

	nand_command(block, page, 0, NAND_CMD_READ0);

	s3c2440_nand_enable_hwecc();
	s3c2440_nand_read_buf(p, eccsize);
	s3c2440_nand_calculate_ecc(&ecc_calc[0]);

	s3c2440_nand_read_buf(oob_data, 64);

	/* Pick the ECC bytes out of the oob data */
	for (i = 0; i < eccbytes; i++)
		ecc_code[i] = oob_data[nand_ecc_pos[i]];

	/* No chance to do something with the possible error message
	 * from correct_data(). We just hope that all possible errors
	 * are corrected by this routine.
	 */
	//this->ecc.correct(mtd, p, &ecc_code[i], &ecc_calc[i]);

	return 0;
}

static int nand_load(unsigned int offs, unsigned int uboot_size, unsigned char *dst)
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
		if (!nand_is_bad_block(block)) {
			/*
			 * Skip bad blocks
			 */
			while (page < CONFIG_SYS_NAND_PAGE_COUNT) {
				nand_read_page(block, page, dst);
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
	__attribute__((noreturn)) void (*uboot)(void);

	/*
	 * Init board specific nand support
	 */
	board_nand_init();

	s3c2440_nand_select_chip(0);

	/*
	 * Load U-Boot image from NAND into RAM
	 */
	nand_load(CONFIG_SYS_NAND_U_BOOT_OFFS, CONFIG_SYS_NAND_U_BOOT_SIZE,
		  (unsigned char *)CONFIG_SYS_NAND_BOOT_START);

	s3c2440_nand_select_chip(-1);

	/*
	 * Jump to U-Boot image
	 */
	uboot = (void *)CONFIG_SYS_NAND_BOOT_START;
	(*uboot)();
}
