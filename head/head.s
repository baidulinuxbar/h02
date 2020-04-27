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
	call copy_bios
	pushl $bios
	pushl $KS_DS
	call dump_mem
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
