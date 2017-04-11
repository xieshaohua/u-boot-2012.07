
#ifndef __INIT_H__
#define __INIT_H__

/* some parameters for the board */
#define LOCKTIME		0x4c000000
#define MPLLCON			0x4c000004 
#define UPLLCON			0x4c000008 
#define CLKDIVN			0x4C000014	/* clock divisor register */

#define WTCON			0x53000000
#define INTMSK			0x4a000008	/* Interrupt-Controller base addresses */
#define INTSUBMSK		0x4A00001C

#define BWSCON			0x48000000

#define GPFCON			0x56000050
#define GPFDAT			0x56000054


/* Fout = 400MHz, Fin = 12MHz Uclk = 96MHz */
#define M_MDIV			(0x5c)
#define M_PDIV			(0x1)
#define M_SDIV			(0x1)

#define U_M_MDIV		(0x38)
#define U_M_PDIV		(0x2)
#define U_M_SDIV		(0x2)


/* BWSCON */
#define DW8			(0x0)
#define DW16			(0x1)
#define DW32			(0x2)
#define WAIT			(0x1<<2)
#define UBLB			(0x1<<3)

#define B1_BWSCON		(DW32)
#define B2_BWSCON		(DW16)
#define B3_BWSCON		(DW16 + WAIT + UBLB)
#define B4_BWSCON		(DW16)
#define B5_BWSCON		(DW16)
#define B6_BWSCON		(DW32)
#define B7_BWSCON		(DW32)

/* BANK0CON */
#define B0_Tacs			0x0	/*  0clk */
#define B0_Tcos			0x0	/*  0clk */
#define B0_Tacc			0x7	/* 14clk */
#define B0_Tcoh			0x0	/*  0clk */
#define B0_Tah			0x0	/*  0clk */
#define B0_Tacp			0x0
#define B0_PMC			0x0	/* normal */

/* BANK1CON */
#define B1_Tacs			0x0	/*  0clk */
#define B1_Tcos			0x0	/*  0clk */
#define B1_Tacc			0x7	/* 14clk */
#define B1_Tcoh			0x0	/*  0clk */
#define B1_Tah			0x0	/*  0clk */
#define B1_Tacp			0x0
#define B1_PMC			0x0

#define B2_Tacs			0x0
#define B2_Tcos			0x0
#define B2_Tacc			0x7
#define B2_Tcoh			0x0
#define B2_Tah			0x0
#define B2_Tacp			0x0
#define B2_PMC			0x0

#define B3_Tacs			0x0	/*  0clk */
#define B3_Tcos			0x3	/*  4clk */
#define B3_Tacc			0x7	/* 14clk */
#define B3_Tcoh			0x1	/*  1clk */
#define B3_Tah			0x0	/*  0clk */
#define B3_Tacp			0x3     /*  6clk */
#define B3_PMC			0x0	/* normal */

#define B4_Tacs			0x0	/*  0clk */
#define B4_Tcos			0x0	/*  0clk */
#define B4_Tacc			0x7	/* 14clk */
#define B4_Tcoh			0x0	/*  0clk */
#define B4_Tah			0x0	/*  0clk */
#define B4_Tacp			0x0
#define B4_PMC			0x0	/* normal */

#define B5_Tacs			0x0	/*  0clk */
#define B5_Tcos			0x0	/*  0clk */
#define B5_Tacc			0x7	/* 14clk */
#define B5_Tcoh			0x0	/*  0clk */
#define B5_Tah			0x0	/*  0clk */
#define B5_Tacp			0x0
#define B5_PMC			0x0	/* normal */

#define B6_MT			0x3	/* SDRAM */
#define B6_Trcd			0x1
#define B6_SCAN			0x1	/* 9bit */

#define B7_MT			0x3	/* SDRAM */
#define B7_Trcd			0x1	/* 3clk */
#define B7_SCAN			0x1	/* 9bit */

/* REFRESH parameter */
#define REFEN			0x1	/* Refresh enable */
#define TREFMD			0x0	/* CBR(CAS before RAS)/Auto refresh */
#define Trp			0x0	/* 2clk */
#define Trc			0x3	/* 7clk */
#define Tchr			0x2	/* 3clk */
#define REFCNT			1113	/* period=15.6us, HCLK=60Mhz, (2048+1-15.6*60) */



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

#endif /* __INIT_H__ */
