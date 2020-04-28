/*toys
 *head：main-head file
 *Copyright (C) 2020-2022 tybitsfox
 */
PROTECT_MODE	=	1
.include "defconst.s"
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	lss	stk,%esp
	movl %esp,%ebp
	call copy_bios
	pushl $bios
	pushl $KS_DS
	call dump_mem
	cli
	call setup_idt			#setup idt
	lidt l_idt
	call reset_gdt			#reset gdt
	lgdt l_gdt
	jmp $8,$1f
1:
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	lss stk,%esp
	movl %esp,%ebp
	call setup_ldt
	call setup_tss
	call setup_pdt
	movl $PDT_OFF,%eax
	movl %eax,%cr3
	movl %cr0,%eax
	orl $0x80000000,%eax
	movl %eax,%cr0			#enable page model
	jmp $KS_CS,$2f
2:	
	movl $KS_LDT0,%eax
	lldt %ax				#enable ldt
	movl $KS_TSS0,%eax
	ltr %ax					#enable tss
	movl $0,%eax
	outb %al,$0x21
	jmp .+2
	outb %al,$0xa1
	sti
	pushl $0x20
	call delay
	movl _lcount,%ebx
	movl %ebp,%esp
	jmp .
.include "funcs/foth.s"
.include "funcs/fint.s"
.include "driver/hdd/hdd_func.s"
.include "driver/flp/flp_func.s"
.include "driver/hdd/hdd_var.s"
.include "driver/flp/flp_var.s"
.include "funcs/fvar.s"

.org	SAFE_BUFF-4
.ascii	"yong"
