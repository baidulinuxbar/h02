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
	movl $SAFE_BUFF,%eax
	movl %eax,%ebx
	jmp .
.include "funcs/foth.s"
.include "funcs/fint.s"
.include "driver/hdd/hdd_func.s"
.include "driver/flp/flp_func.s"
.include "driver/hdd/hdd_var.s"
.include "driver/flp/flp_var.s"
.include "funcs/fvar.s"


#63*512=32256
.org	32252
.ascii	"ttyy"


