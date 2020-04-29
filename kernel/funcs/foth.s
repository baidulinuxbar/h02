/*toys
 *kernel：basic functions inherited from head model
 *and deleted unused functions: setup_ldt,setup_tss,setup_pdt,reset_gdt
 *changed dump_mem unused safe buffer
 *Copyright (C) 2020-2022 tybitsfox
 */
//{{{set_cursor		保护模式下的光标设置函数
/*传入参数：无，依据系统变量_cursor_pos设定光标位置
  作用：设定当前光标位置
  _cursor_pos低8位保存行号，高8位保存列号。
  返回值：无
 */
set_cursor:
	push %ds
	movl $KS_DS,%eax
	movw %ax,%ds
	movl _cursor_pos,%ebx
	movl $0,%eax
	xchgb %al,%bl
	movl $80,%ecx
	mulb %cl
	xchgb %bl,%bh
	addw %ax,%bx		#save index of disp buffer(row*80+col)
	movb $0xf,%al
	movw $0x3d4,%dx
	outb %al,%dx
	incw %dx
	movb %bl,%al
	outb %al,%dx
	movb $0xe,%al
	movw $0x3d4,%dx
	outb %al,%dx
	incw %dx
	movb %bh,%al
	outb %al,%dx
	pop %ds
	ret
//}}}
//{{{cls	保护模式下的清屏函数
/*传入参数：无
  作用：清屏，并重置光标位置：0

  返回值：无
 */
cls:
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl $DISP_BUFF,%edi
	movl $0x1000,%ecx
	movl $0x720,%eax
	rep stosw
	movw $0,_cursor_pos
	call set_cursor
	pop %es
	ret
//}}}
//{{{calc_cursor	计算光标位置
/*传入参数：待显示字符串的长度，
  传入方式：堆栈
  作用：该函数主要用于计算待输入字符串与原光标位置是否超出一屏，如超出则清屏
  		否则_cursor_pos不变。
  
  返回值：ax=显示输出的行号（0-base）*160,即显示缓冲区的显示地址		
 */
calc_cursor:
	pushl %ebp
	movl %esp,%ebp
	push %ds
	movl $KS_DS,%eax
	movw %ax,%ds
	movl 8(%ebp),%eax
	movl _cursor_pos,%ebx		#bl保存原行数，bh保存原列数
	movl $80,%ecx
	divb %cl					#al保存行数，ah保存列数
	cmpb $0,%ah
	je 1f
	addb $1,%al
1:
	addb %bl,%al
	cmpb $24,%al
	jbe 2f
	call cls
2:
	movl _cursor_pos,%ebx
	cmpb $0,%bh
	je 3f
	addb $1,%bl
3:
	movl $0,%eax
	movb %bl,%al
	movl $0,%edx
	movl $160,%ecx
	mulb %cl					#ax中保存了显示缓冲地址(仅计算的行，从行开始显示)
	pop %ds
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{show_msg	显示信息
/*传入参数：字符串地址，长度
  para1 12(%ebp):	buffer
  para2 8(%ebp):	length

  返回值：无
  逻辑实现：1、调用calc_cursor计算光标，
  			2、使用calc_cursor的返回值设置显示位置，显示输出字符串
			3、修改_cursor_pos，并且调用set_cursor移动光标.
 */
show_msg:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	cmpl $0x200,%eax		#设定字符串最大512字节
	jae 3f
	movl 12(%ebp),%esi
	movl 8(%ebp),%ecx
	pushl %ecx
	call calc_cursor
	popl %ecx
	movl %eax,%edi
	addl $DISP_BUFF,%edi
	movl $KS_DS,%eax
	movw %ax,%es
	movl $0xb00,%eax
1:
	lodsb
	stosw
	loop 1b
	movl 8(%ebp),%eax
	movl $0,%edx
	movl $80,%ecx
	divb %cl
	movl _cursor_pos,%ebx
	cmpb $0,%bh
	je 2f
	incl %eax
2:
	addb %bl,%al
	movl %eax,_cursor_pos
	call set_cursor
3:
	movl %ebp,%esp
	popl %ebp
	ret
//}}}	
//{{{dump_mem	每行显示16字节的内存数据
/*传入参数：内存地址，段选择符
  传递方式：堆栈
  			12（%ebp） 内存地址
			8（%ebp）连续显示的行数 default：1-5
  作用：将指定内存位置的16字节以16进制的形式显示			
  返回值：无			
 */	
dump_mem:
	pushl %ebp
	movl %esp,%ebp
	push %ds
	push %es
	cmpl $0xfffb0,12(%ebp)
	ja  6f
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	movl 12(%ebp),%esi
	movl 8(%ebp),%ecx
	cmpl $1,%ecx
	ja 1f
	movl $1,%ecx
1:
	cmpl $5,%ecx
	jbe 2f
	movl $5,%ecx
2:
	pushl %ecx
	movl $16,%eax
	pushl %eax
	call calc_cursor
	popl %ebx
	movl %eax,%edi		#取得显示缓冲区中的显示位置
	addl $DISP_BUFF,%edi
	movl $16,%ecx		#显示固定长度的内存数据
3:
	movl $0xc00,%eax
	lodsb
	movb %al,%bl
	shrb $4,%al
	cmpb $9,%al
	jbe 4f
	addb $7,%al
4:
	addb $0x30,%al
	stosw
	movb %bl,%al
	andb $0xf,%al
	cmpb $9,%al
	jbe 5f
	addb $7,%al
5:
	addb $0x30,%al
	stosw
	movl $0x720,%eax
	stosw
	loop 3b				#按16进制显示目标内存信息
	movl _cursor_pos,%eax
	incl %eax
	movb $48,%ah
	movl %eax,_cursor_pos	#计算新的光标位置
	call set_cursor			#移动光标
	popl %ecx
	loop 2b
6:	
	pop %es
	pop %ds
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{copy_bios	将保存的软驱参数和物理内存拷贝至新位置
copy_bios:
	leal bios,%edi
	movl $0x50400,%esi
	movl $36,%ecx
	rep movsb
	ret
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
	cmpl $0xff,%eax
	ja 1f
	andl $0xff,%eax
	int $0x80
1:
	movl %ebp,%esp
	popl %ebp
	ret
//}}}



