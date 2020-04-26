PROTECT_MODR	=	1
.include "defconst.s"
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	lss	stk,%esp
	jmp .

stk:	.long	0x5000,0x10

.org	1020
.ascii	"yong"
