/*
 * Memory Setup stuff - taken from blob memsetup.S
 *
 * Copyright (C) 1999 2000 2001 Erik Mouw (J.A.K.Mouw@its.tudelft.nl) and
 *                     Jan-Derk Bakker (J.D.Bakker@its.tudelft.nl)
 *
 * Modified for the Samsung SMDK2410 by
 * (C) Copyright 2002
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


#include <config.h>
#include <version.h>


/* some parameters for the board */

/*
 *
 * Taken from linux/arch/arm/boot/compressed/head-s3c2410.S
 *
 * Copyright (C) 2002 Samsung Electronics SW.LEE  <hitchcar@sec.samsung.com>
 *
 */
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
/**************************************/

_TEXT_BASE:
	.word	CONFIG_SYS_TEXT_BASE

.globl lowlevel_init
lowlevel_init:

	/* turn off the watchdog */
	ldr	r0, =WTCON
	mov	r1, #0x0
	str	r1, [r0]

	/* mask all IRQs by setting all bits in the INTMR - default */
	mov	r1, #0xffffffff
	ldr	r0, =INTMSK
	str	r1, [r0]
	ldr	r1, =0x7ff
	ldr	r0, =INTSUBMSK
	str	r1, [r0]

	/* FCLK:HCLK:PCLK = 1:4:8, default FCLK is 400 MHz ! */
	ldr	r0, =CLKDIVN
	mov	r1, #5
	str	r1, [r0]

	/* system_clock_init: Initialize core clock and bus clock */
	mrc	p15, 0, r0, c1, c0, 0		/* read ctrl register   */
	orr	r0, r0, #0xc0000000		/* Asynchronous	    */
	mcr	p15, 0, r0, c1, c0, 0		/* write ctrl register  */

	/* to reduce PLL lock time, adjust the LOCKTIME register */
	ldr	r0, =LOCKTIME
	ldr	r1, =0xFFFFFF
	str	r1, [r0]

	/* configure UPLL and MPLL */
	ldr	r0, =UPLLCON
	ldr	r1, =((U_M_MDIV<<12)+(U_M_PDIV<<4)+U_M_SDIV)
	str	r1, [r0]
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ldr	r0, =MPLLCON
	ldr	r1, =((M_MDIV<<12)+(M_PDIV<<4)+M_SDIV)
	str	r1, [r0]
	nop
	nop
	nop
	nop

	/* init led ports, turn off all leds */
	ldr	r0, =GPFCON
	ldr	r1, =(1<<(6*2))|(1<<(5*2))|(1<<(4*2))
	str	r1, [r0]
	ldr	r0, =GPFDAT
	ldr	r1, =(1<<6)|(1<<5)|(1<<4)
	str	r1, [r0]

	/* memory control configuration */
	/* make r0 relative the current location so that it */
	/* reads SMRDATA out of FLASH rather than memory ! */
	ldr     r0, =SMRDATA
	ldr	r1, _TEXT_BASE
	sub	r0, r0, r1
	add	r0, r0, r1
	ldr	r1, =BWSCON	/* Bus Width Status Controller */
	add     r2, r0, #13*4
0:
	ldr     r3, [r0], #4
	str     r3, [r1], #4
	cmp     r2, r0
	bne     0b

	/* everything is fine now */
	mov	pc, lr

	.ltorg
/* the literal pools origin */

SMRDATA:
    .word (0+(B1_BWSCON<<4)+(B2_BWSCON<<8)+(B3_BWSCON<<12)+(B4_BWSCON<<16)+(B5_BWSCON<<20)+(B6_BWSCON<<24)+(B7_BWSCON<<28))
    .word ((B0_Tacs<<13)+(B0_Tcos<<11)+(B0_Tacc<<8)+(B0_Tcoh<<6)+(B0_Tah<<4)+(B0_Tacp<<2)+(B0_PMC))
    .word ((B1_Tacs<<13)+(B1_Tcos<<11)+(B1_Tacc<<8)+(B1_Tcoh<<6)+(B1_Tah<<4)+(B1_Tacp<<2)+(B1_PMC))
    .word ((B2_Tacs<<13)+(B2_Tcos<<11)+(B2_Tacc<<8)+(B2_Tcoh<<6)+(B2_Tah<<4)+(B2_Tacp<<2)+(B2_PMC))
    .word ((B3_Tacs<<13)+(B3_Tcos<<11)+(B3_Tacc<<8)+(B3_Tcoh<<6)+(B3_Tah<<4)+(B3_Tacp<<2)+(B3_PMC))
    .word ((B4_Tacs<<13)+(B4_Tcos<<11)+(B4_Tacc<<8)+(B4_Tcoh<<6)+(B4_Tah<<4)+(B4_Tacp<<2)+(B4_PMC))
    .word ((B5_Tacs<<13)+(B5_Tcos<<11)+(B5_Tacc<<8)+(B5_Tcoh<<6)+(B5_Tah<<4)+(B5_Tacp<<2)+(B5_PMC))
    .word ((B6_MT<<15)+(B6_Trcd<<2)+(B6_SCAN))
    .word ((B7_MT<<15)+(B7_Trcd<<2)+(B7_SCAN))
    .word ((REFEN<<23)+(TREFMD<<22)+(Trp<<20)+(Trc<<18)+(Tchr<<16)+REFCNT)
    .word 0x32
    .word 0x30
    .word 0x30


/*
 * led function, include led init and led on/off
 */
	.globl	led1_on
led1_on:
	ldr	r0, =GPFDAT
	ldr	r1, [r0]
	bic	r1, r1, #(1<<4)
	str	r1, [r0]
	mov	pc, lr
    
	.globl	led1_off
led1_off:
	ldr	r0, =GPFDAT
	ldr	r1, [r0]
	orr	r1, r1, #(1<<4)
	str	r1, [r0]
	mov	pc, lr
    
	.globl	led2_on
led2_on:
	ldr	r0, =GPFDAT
	ldr	r1, [r0]
	bic	r1, r1, #(1<<5)
	str	r1, [r0]
	mov	pc, lr
    
	.globl	led2_off
led2_off:
	ldr	r0, =GPFDAT
	ldr	r1, [r0]
	orr	r1, r1, #(1<<5)
	str	r1, [r0]
	mov	pc, lr

	.globl	led3_on
led3_on:
	ldr	r0, =GPFDAT
	ldr	r1, [r0]
	bic	r1, r1, #(1<<6)
	str	r1, [r0]
	mov	pc, lr

	.globl	led3_off
led3_off:
	ldr	r0, =GPFDAT
	ldr	r1, [r0]
	orr	r1, r1, #(1<<6)
	str	r1, [r0]
	mov	pc, lr
