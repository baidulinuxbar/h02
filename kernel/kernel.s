/*toys
 *kernel：main-kernel file
 *Copyright (C) 2020-2022 tybitsfox
 */
PROTECT_MODE	=	1
.include "defconst.s"
.text
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	movw %ax,%gs
	lss stk,%esp
	movl $0x123abc,%eax
	movl %eax,%ebx
	jmp .
.align 2
stk:	.long ESP_LEN,KS_SS	

#63*512=32256
.org	32252
.ascii	"ttyy"


