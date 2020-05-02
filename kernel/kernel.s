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
	call ord_int
	jmp .
	call _in_main
	jmp .

.data
.align 2
stk:			.long	ESP_LEN,KS_SS

