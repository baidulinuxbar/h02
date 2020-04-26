PROTECT_MODE	=	1
.include "defconst.s"
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	lss	stk,%esp
	call cls
	jmp .
.include "funcs/foth.s"
.align 2
stk:	.long	SS_STACK,KS_SS
_lcount:		.long	0
_flp_flag:		.long	0
bios:			.space	12,0
hd_bios:		.space	16,0
pmem_size:		.long	0
_cursor_pos:	.long	0
				.long	0				#for safe
.align 2

.org	SAFE_BUFF-4
.ascii	"yong"
