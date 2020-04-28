/*toys
 *head：normal functions 
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
	cmpl $0x100,%eax		#设定字符串最大255字节
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
//{{{dump_mem	显示16字节的内存数据
/*传入参数：内存地址，段选择符
  传递方式：堆栈
  			12（%ebp） 内存地址
			8（%ebp）段选择符
  作用：将指定内存位置的16字节以16进制的形式显示			
  返回值：无			
 */	
dump_mem:
	pushl %ebp
	movl %esp,%ebp
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl $SAFE_BUFF,%edi
	movl 12(%ebp),%esi
	movl 8(%ebp),%eax
	movw %ax,%ds
	movl $48,%ecx
	rep movsb			#首先将待显示缓冲数据移动至安全缓冲区
	push %es
	pop %ds
	movl $KS_DS,%eax
	movw %ax,%es
	movl $SAFE_BUFF,%esi
	movl $3,%ecx
1:	
	pushl %ecx
	movl $16,%eax
	pushl %eax
	call calc_cursor
	popl %ebx
	movl %eax,%edi		#取得显示缓冲区中的显示位置
	addl $DISP_BUFF,%edi
	movl $16,%ecx		#显示固定长度的内存数据
4:
	movl $0xc00,%eax
	lodsb
	movb %al,%bl
	shrb $4,%al
	cmpb $9,%al
	jbe 5f
	addb $7,%al
5:
	addb $0x30,%al
	stosw
	movb %bl,%al
	andb $0xf,%al
	cmpb $9,%al
	jbe 6f
	addb $7,%al
6:
	addb $0x30,%al
	stosw
	movl $0x720,%eax
	stosw
	loop 4b				#按16进制显示目标内存信息
	movl _cursor_pos,%eax
	incl %eax
	movb $48,%ah
	movl %eax,_cursor_pos	#计算新的光标位置
	call set_cursor			#移动光标
	popl %ecx
	loop 1b

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
//{{{setup_tss	tss的安装函数
/*将tss0和tss1拷贝至指定位置*/	
setup_tss:
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	leal tss0,%ebx
	leal tss_lnk,%esi
	movl $3,%ecx
1:
	pushl %ecx
	lodsl
	movl %eax,%edi
	lodsl
	movl %eax,8(%ebx)	#系统级堆栈
	lodsl
	movl %eax,28(%ebx)	#pdt
	lodsl
	movl %eax,96(%ebx)	#ldt
	pushl %esi
	movl %ebx,%esi
	movl $104,%ecx
	rep movsb
	popl %esi
	popl %ecx
	loop 1b

	pop %es
	pop %ds
	ret
//}}}	
//{{{setup_pdt
/*安装页目录和页表*/	
setup_pdt:
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	movl $PDT_OFF,%edi
	movl $0x400,%ecx
	movl $0,%eax
	rep stosl				#clear
	movl $4,%ecx
	movl $PDT_OFF,%edi
	movl $PT_SYS_OFF,%eax
	addl $7,%eax
1:
	stosl
	addl $PDT_LEN,%eax
	loop 1b				#安装页目录
	movl $PT_SYS_OFF,%edi
	movl $7,%eax
	movl $0x1000,%ecx
2:
	stosl
	addl $PDT_LEN,%eax
	loop 2b				#安装完4个页表，可映射16M
	pop %es
	pop %ds
	ret
//}}}
//{{{reset_gdt 安装新的GDT
reset_gdt:
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	movl $GDT_OFF,%edi
	movl $GDT_LEN,%ecx
	incl %ecx
	movl $0,%eax
	rep stosb
	movl $GDT_OFF,%edi
	addl $8,%edi			#zero for first 8 bytes
	leal gdt_lnk,%esi
	movl $12,%ecx
1:	
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
	stosl
	addl $16,%esp
	loop 1b
	pop %es
	pop %ds
	ret
//}}}







