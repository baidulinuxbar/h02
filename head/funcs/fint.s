/*toys
 *head：int functions 
 *Copyright (C) 2020-2022 tybitsfox
 */
//{{{copy_bios	将保存的软驱参数和物理内存拷贝至新位置
copy_bios:
	leal bios,%edi
	movl $0x50400,%esi
	movl $36,%ecx
	rep movsb
	ret
//}}}
//{{{nor_int	通用中断处理程序
nor_int:
	pusha
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl $460,%edi
	addl $DISP_BUFF,%edi
	movl $0xb41,%eax
	stosw
	pop %es
	popa
	iret
//}}}
//{{{int_a	8259a master interrupt
int_a:
	pusha
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl $462,%edi
	addl $DISP_BUFF,%edi
	movl $0xb42,%eax
	stosw
	movl $0x20,%eax
	outb %al,$0x20
	pop %es
	popa
	iret
//}}}
//{{{int_b	8259a slave interrupt
int_b:
	pusha
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl $464,%edi
	addl $DISP_BUFF,%edi
	movl $0xb43,%eax
	stosw
	movl $0x20,%eax
	outb %al,$0xa0
	jmp .+2
	jmp .+2
	outb %al,$0x20
	pop %es
	popa
	iret
//}}}	
//{{{time_int	0x20
time_int:
	pusha
	push %ds
	movl $KS_DS,%eax
	movw %ax,%ds
	addl $1,_lcount
	movl $0x20,%eax
	outb %al,$0x20
	pop %ds
	popa
	iret
//}}}
//{{{flp_int	0x26
flp_int:
	pusha
	push %ds
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $1,_flp_flag
	movl $0x20,%eax
	outb %al,$0x20
	pop %ds
	popa
	iret
//}}}
//{{{hd0_int	0x2E
hd0_int:
	pusha
	push %ds
	movl $KS_DS,%eax
	movw %ax,%ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl $466,%edi
	addl $DISP_BUFF,%edi
	movl $0xb44,%eax
	stosw
	pop %es
	movl $0x20,%eax
	outb %al,$0xa0
	jmp .+2
	outb %al,$0x20
	cmpb $HD_INT_ERR,hd_fin_int #status ready & succ are allowed
	je 1f
	call hdd_int
1:	
	pop %ds
	popa
	iret
//}}}	
//{{{sys_int	system call
sys_int:
	pushl %ebx
	push %ds
	cmpb $0,%ah
	jne 9f
	movl $KS_DS,%ebx
	movw %bx,%ds
	andl $0xff,%eax
	addl _lcount,%eax
1:
	jmp .+2
	jmp .+2
	cmpl _lcount,%eax
	jmp .+2
	ja 1b
9:	
	pop %ds
	popl %ebx
	iret
//}}}	
//{{{delay 延时函数
/*传入参数：延时数，最大255*1/100秒
 *传递方式：堆栈
 *返回值：无
 */	
delay:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	cmpl $0xff,%ax
	ja 1f
	andl $0xff,%ax
	int $0x80
1:
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{crt_gdt_seg	生成gdt段描述符,注意：本函数不能生成门描述符
/*传入参数：段基地址，段限长，段类型，颗粒度
  传入方式：堆栈，其中：
  			20(%ebp)：颗粒度
			16(%ebp)：段类型
			12(%ebp)：段限长
			8(%ebp) ：段基地址
  返回值：eax:edx
 */	
crt_gdt_seg:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %esi
	movl 8(%ebp),%eax
	rorl $16,%eax			#segment base,big-enddin
	movl 12(%ebp),%edx
	andl $0xfffff,%edx		#be sure 20-bits available
	movl 16(%ebp),%ebx
	testl $0x10,%ebx		#test segment type
	jnz	1f					#data or text seg
	movl $0,%esi
	jmp 2f
1:
	movl $0x80,%esi
2:
	movl 20(%ebp),%ecx
	orl %esi,%ecx
	rorb $1,%cl
	movb %cl,%bh
	bswap %ebx
	addl %ebx,%edx
	xchgw %ax,%dx
	rorl $8,%edx
	bswap %edx
	popl %esi
	popl %ecx
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
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
	cmpl $TRAP_GATE,%ebx
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
	leal nor_int,%edx
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
	leal int_a,%edx
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
	leal int_b,%edx
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
	leal hd0_int,%edx
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

//{{{setup_ldt	ldt的安装函数
/*将ldt0和ldt1拷贝至指定位置
  已经连续两次在ldt的加载时出错了，出错的原因也都一样，好好检查GDT和LDT，看是否漏掉一个word!!!
 */	
setup_ldt:
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $KS_DS,%eax
	movw %ax,%es
	movl $0,%eax
	movl $LDT_OFF,%edi
	movl $0x120,%ecx		#48*6=0x120
	rep stosw				#clear ldt0,ldt1
	movl $LDT_OFF,%edi
	subl $8,%edi			#adjust position
	leal ldt_lnk,%esi
	movl $3,%ecx			#3ldts 4 seg description peer ldt
1:	
	pushl %ecx
	addl $16,%edi
	movl $4,%ecx
2:
	lodsl
	pushl %eax
	lodsl
	pushl %eax
	lodsl
	pushl %eax
	lodsl
	pushl %eax
	call crt_gdt_seg
	stosl
	xchgl %eax,%edx
	stosl					#ldt1 text	0xf
	addl $16,%esp
	loop 2b
	popl %ecx
	decl %ecx
	cmpl $0,%ecx
	ja  1b
	pop %es
	pop %ds
	ret
//}}}





