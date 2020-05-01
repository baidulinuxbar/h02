/*toys
 *kernel：main-kernel file
 *Copyright (C) 2020-2022 tybitsfox
 */
PROTECT_MODE	=	1
#for changed new buffer address
SAFE_CHANGED	=	1		
.include "defconst.s"
.text
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	movw %ax,%gs
	lss stk,%esp
	movl %esp,%ebp
	movl $SAFE_BUFF,%eax
	movl %eax,%ebx
	pushl %esi
	call init_kd
	jmp .
.include "funcs/foth.s"
.include "funcs/fint.s"
.include "driver/hdd/hdd_func.s"
.include "driver/flp/flp_func.s"
.include "driver/hdd/hdd_var.s"
.include "driver/flp/flp_var.s"
.include "funcs/fvar.s"

aa:	.long 0
.space	16,0
#63*512=32256
#.org	32252
#.ascii	"ttyy"


