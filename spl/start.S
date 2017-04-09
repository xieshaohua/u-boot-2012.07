
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


	ldr	r0, _nand_boot
	mov	pc, r0
	
_nand_boot:
	.word nand_boot



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
