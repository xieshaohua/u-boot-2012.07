
#include "init.h"

.globl _start
_start:
	b	start_code

	. = _start + 64
	.balignl 16,0xdeadbeef

/*
 * These are defined in the board-specific linker script.
 */
_bss_start:
	.word __bss_start

_bss_end:
	.word __bss_end__

/*
 * the actual start code
 */
start_code:
	/*
	 * set the cpu to SVC32 mode
	 */
	mrs	r0, cpsr
	bic	r0, r0, #0x1f
	orr	r0, r0, #0xd3
	msr	cpsr, r0
	
	/*
	 * we do sys-critical inits only at reboot,
	 * not when booting from ram!
	 */
	bl	cpu_init_crit

/* Set stackpointer in SDRAM before CONFIG_SYS_NAND_BOOT_START */
	ldr	sp, =0x33F00000
	bic	sp, sp, #7 /* 8-byte alignment for ABI compliance */


clear_bss:
	ldr	r0, _bss_start
	ldr	r1, _bss_end
	mov	r2, #0x00000000

clbss_l:
	cmp	r0, r1			/* clear loop... */
	bhs	clbss_e 		/* if reached end of bss, exit */
	str	r2, [r0]
	add	r0, r0, #4
	b	clbss_l
clbss_e:


	bl	nand_boot


/*
 *************************************************************************
 *
 * CPU_init_critical registers
 *
 * setup important registers
 * setup memory timing
 *
 *************************************************************************
 */
cpu_init_crit:
	/*
	 * flush v4 I/D caches
	 */
	mov	r0, #0
	mcr	p15, 0, r0, c7, c7, 0	/* flush v3/v4 cache */
	mcr	p15, 0, r0, c8, c7, 0	/* flush v4 TLB */

	/*
	 * disable MMU stuff and caches
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00002300	@ clear bits 13, 9:8 (--V- --RS)
	bic	r0, r0, #0x00000087	@ clear bits 7, 2:0 (B--- -CAM)
	orr	r0, r0, #0x00000002	@ set bit 2 (A) Align
	orr	r0, r0, #0x00001000	@ set bit 12 (I) I-Cache
	mcr	p15, 0, r0, c1, c0, 0

	/*
	 * before relocating, we have to setup RAM timing
	 * because memory timing is board-dependend, you will
	 * find a lowlevel_init.S in your board directory.
	 */
	mov	ip, lr

	bl	lowlevel_init

	mov	lr, ip
	mov	pc, lr



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
	mrc	p15, 0, r0, c1, c0, 0		/* read ctrl register	*/
	orr	r0, r0, #0xc0000000		/* Asynchronous     */
	mcr	p15, 0, r0, c1, c0, 0		/* write ctrl register	*/

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
	ldr	r0, =SMRDATA
	ldr	r1, =0x0
	sub	r0, r0, r1
	add	r0, r0, r1
	ldr	r1, =BWSCON	/* Bus Width Status Controller */
	add	r2, r0, #13*4
0:
	ldr	r3, [r0], #4
	str	r3, [r1], #4
	cmp	r2, r0
	bne	0b

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

