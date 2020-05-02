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
	cli
	movl $0xff,%eax
	outb %al,$0x21
	jmp .+2
	outb %al,$0xa1
	jmp .+2
	call setup_idt
	sti
	movl $0,%eax
	outb %al,$0x21
	jmp .+2
	outb %al,$0xa1
	jmp .+2
#	call ord_int
#	jmp .
	movl %ebp,%esp
	call _in_main
	jmp .
//{{{crt_tab_gate	生成门描述符
/*传入参数：段选择符，段内偏移，段类型，D对调用门传入的参数个数
  传入方法：堆栈，其中：
	20(%ebp):参数个数，除调用门外，这个没用
	16(%ebp):段选择符
	12(%ebp):段类型
	8(%ebp):段内偏移	任务门段内偏移不用，但必须有压栈操作
  返回值:	eax:edx
*/
crt_tab_gate:
	pushl %ebp
	movl %esp,%ebp
	movl 12(%ebp),%ebx	#段类型
	cmpl $CALL_GATE,%ebx		#调用门
	jne 1f
	movl 8(%ebp),%edx
	xchgb %bh,%bl
	movl 20(%ebp),%eax
	andl $0xf,%eax
	addl %eax,%ebx
	movl 16(%ebp),%eax
	shll $16,%eax
	addl %ebx,%eax
	xchgw %ax,%dx
	jmp 9f
1:
	cmpl $TASK_GATE,%ebx		#任务门
	jne 2f
	xchgb %bh,%bl
	movl $0,%edx		#任务门段内偏移无用
	movl 16(%ebp),%eax
	shll $16,%eax
	addl %ebx,%eax
	xchgw %ax,%dx
	jmp 9f	
2:
	cmpl $INT_GATE,%ebx
	je 3f
	cmpl $TRAP_GATE,%ebx		#陷阱门
	je 3f
	movl $0,%eax
	movl $0,%edx
	jmp 9f
3:
	xchgb %bh,%bl
	movl 16(%ebp),%eax
	shll $16,%eax
	addl %ebx,%eax
	movl 8(%ebp),%edx
	xchgw %ax,%dx
9:	
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{setup_idt
setup_idt:
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $KS_DS,%eax
	movw %ax,%es
	movl $IDT_OFF,%edi
	pushl $KS_CS
	pushl $INT_GATE
	leal ord_int,%edx
	pushl %edx
	call crt_tab_gate
	movl $256,%ecx
1:
	stosl
	xchgl %eax,%edx
	stosl
	xchgl %eax,%edx
	loop 1b					#setup nor_int
	movl $0x100,%edi
	addl $4,%esp
	leal irq_m_int,%edx
	pushl %edx
	call crt_tab_gate
	movl $8,%ecx
2:
	stosl
	xchgl %eax,%edx
	stosl
	xchgl %eax,%edx
	loop 2b					#setup int_a
	addl $4,%esp
	movl $0x140,%edi
	leal irq_s_int,%edx
	pushl %edx
	call crt_tab_gate
	movl $8,%ecx
3:
	stosl
	xchgl %eax,%edx
	stosl
	xchgl %eax,%edx
	loop 3b					#setup int_b
	addl $4,%esp
	movl $0x100,%edi
	leal time_int,%edx
	pushl %edx
	call crt_tab_gate
	stosl
	xchgl %eax,%edx
	stosl					#setup time_int
	addl $4,%esp
	movl $0x130,%edi
	leal flp_int,%edx
	pushl %edx
	call crt_tab_gate
	stosl
	xchgl %eax,%edx
	stosl					#setup flp_int
	addl $4,%esp
	movl $0x170,%edi
	leal hd_int,%edx
	pushl %edx
	call crt_tab_gate		#setup hd0_int
	stosl
	xchgl %eax,%edx
	stosl
	addl $8,%esp
	movl $0x400,%edi
	pushl $TRAP_GATE		#trap gate
	leal sys_int,%edx
	pushl %edx
	call crt_tab_gate
	stosl
	xchgl %eax,%edx
	stosl					#setup sys_int
	addl $12,%esp
	pop %es
	pop %ds
	ret
//}}}


.data
.align 2
stk:			.long	ESP_LEN,KS_SS

