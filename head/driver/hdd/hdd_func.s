/*toys
 *hard disk driver,
 *normal set is: 20cylinder,64sector,16head,total 9.9M
 *Copyright (C) 2020-2022 tybitsfox
 */
//{{{init_hdd_para	参数初始化函数
/*传入参数：无
 *注意：目前暂不支持主硬盘之外的硬盘操作
  返回值：无
 */
init_hdd_para:
	pushl %ebp
	movl %esp,%ebp
	push %ds
	push %es
	movl $KS_DS,%eax
	movw %ax,%ds
	movw %ax,%es
	leal hd_bios,%esi
	leal hdd_trk,%edi
	movl $16,%ecx
	rep movsb
	movl $SAFE_BUFF,%eax
	movl %eax,hd_data_buf
	pop %es
	pop %ds
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{setup_hdd_para 参数设置函数
/*传入参数：磁头号、柱面号、起始扇区号、读写的扇区数
 *传入方式：堆栈：
 		16(%ebp)	磁头号
		12(%ebp)	柱面号
		8(%ebp)	lwhi 起始扇区号（1-base），lwlo 读写的扇区数
 */
setup_hdd_para:
	pushl %ebp
	movl %esp,%ebp
	movl $KS_DS,%eax
	movw %ax,%ds
	movl 8(%ebp),%eax
	addb %ah,%al
	jc 1f
	cmpb $MAX_SECT_CNT,%al
	jbe 2f
	movl $0xaa00bb,%eax
	jmp .
1:
	movl $0xaabbcc,%eax
	jmp .
2:	
	movl 8(%ebp),%eax
	movb %ah,hd_bsect
	movb %al,hd_csect
	movl 12(%ebp),%eax
	cmpw hdd_trk,%ax
	jb 3f
	movl $0xff11ee22,%eax
	jmp .
3:	
	movb %ah,hd_htrk
	movb %al,hd_ltrk
	movl 16(%ebp),%eax
	cmpb hdd_head,%al
	jb 4f
	movl $0x11ff22ee,%eax
	jmp .
4:	
	movb %al,hd_head
	movl %ebp,%esp
	popl %ebp
	ret
//}}}


//{{{dispatch_hdd_cmd	硬盘控制器命令执行函数
/*传入参数：依据参数表,命令字节通过堆栈
  			8(%ebp): 控制命令字

  返回值：CF cf=1 error,cf=0 success
 */
dispatch_hdd_cmd:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	movb %al,hd_cmd
	cmpl $HD_CMD_RST,%eax
	jne 1f
	jmp 8f
1:
	cmpl $HD_CMD_READ,%eax
	jne 2f
	jmp 8f
2:
	cmpl $HD_CMD_WRITE,%eax
	jne 3f
	jmp 8f
3:
	cmpl $HD_CMD_CHK_SECT,%eax
	jne 4f
	jmp 8f
4:
	cmpl $HD_CMD_FORMAT,%eax
	jne 5f
	jmp 8f
5:
	cmpl $HD_CMD_INIT,%eax
	jne 6f
	jmp 8f
6:
	cmpl $HD_CMD_SEEK,%eax
	jne 7f
	jmp 8f
7:
	cmpl $HD_CMD_DIAG,%eax
	jne 1f
	jmp 8f
1:
	cmpl $HD_CMD_SPEC,%eax
	jne 2f
	jmp 8f
2:
	movb $0,hd_cmd
	stc
	jmp 9f
8:
	call hdd_check_stat
	jc 9f
	movw hdd_precomp,%ax
	shrw $2,%ax				#get precomp
	clc
	movl $HD_PORT_PCOM,%edx
	outb %al,%dx
	jmp .+2
	movb hd_csect,%al		#get sector's counts
	movl $HD_PORT_SECT_CNT,%edx
	outb %al,%dx
	jmp .+2
	movb hd_bsect,%al		#get sector's index
	movl $HD_PORT_SECT_NUM,%edx
	outb %al,%dx
	jmp .+2
	movb hd_ltrk,%al		#get low 8bits cylinder
	movl $HD_PORT_LTRACK,%edx
	outb %al,%dx
	jmp .+2
	movb hd_htrk,%al		#get hi 8bits cylinder
	movl $HD_PORT_HTRACK,%edx
	outb %al,%dx
	jmp .+2
	movb hd_drv,%al
	addb $0xa,%al
	shlb $4,%al
	addb hd_head,%al		#combo 101dhhhh format
	movl $HD_PORT_DRV_HEAD,%edx
	outb %al,%dx
	jmp .+2
	movb hd_cmd,%al			#command
	movl $HD_PORT_COMMAND,%edx
	outb %al,%dx
9:
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{hdd_check_stat	检查状态
/*传入参数：无

  返回值：CF cf=1 error,cf=0 success
 */	
hdd_check_stat:
	pusha
	movl $HD_CTL_DEFAULT,%eax
#	andl $0xf,%eax
	movl $HD_PORT_CTRL,%edx
	outb %al,%dx
	jmp .+2
	movl $HD_PORT_STATUS,%edx
	movl $40,%ecx
1:	
	inb  %dx,%al
	jmp .+2
	jmp .+2
	testb $HD_STAT_BUSY,%al
	jz 2f
	movl $5,%eax
	call delay
	loop 1b
	stc
	jmp 4f
2:	
	inb %dx,%al
	jmp .+2
	testb $HD_STAT_READY,%al
	jnz 3f
	movl $5,%eax
	call delay
	loop 2b
	stc
	jmp 4f
3:
	clc
4:
	popa
	ret
//}}}
//{{{hdd_int	硬盘中断调用的函数
/*传入参数：无
  目前实现了硬盘的读、写响应.
  返回值：错误代码存储于hd_last_err
 */
hdd_int:
	pushl %eax
	pushl %edx
	pushl %ecx
	pushl %esi
	pushl %edi
	movl $HD_PORT_STATUS,%edx
	inb  %dx,%al
	testb $HD_STAT_ERR,%al
	jz 1f
	movl $HD_PORT_ERR,%edx
	inb %dx,%al
	movb %al,hd_last_err
	movb $HD_INT_ERR,hd_fin_int
	jmp 9f
1:
	cmpb $HD_CMD_READ,hd_cmd
	jne 2f
	cld
	push %es
	movl $KS_DS,%eax
	movw %ax,%es
	movl hd_data_buf,%edi
	movl $HD_PORT_DATA,%edx
	movl $256,%ecx
	rep insw
	movl %edi,hd_data_buf		#for repeat muti sectors read
	pop %es
	movb $HD_INT_SUCC,hd_fin_int
	jmp 9f
2:
	cmpb $HD_CMD_WRITE,hd_cmd
	jne 3f
	cld
	movl hd_data_buf,%esi
	movl $HD_PORT_DATA,%edx
	movl $256,%ecx
	rep outsw
	movl %esi,hd_data_buf		#for repeat muti sectors write
	movb $HD_INT_SUCC,hd_fin_int
	jmp 9f
3:
	cmpb $HD_CMD_FORMAT,hd_cmd
	jne 9f
#	add format code here	
9:
	
	popl %edi
	popl %esi
	popl %ecx
	popl %edx
	popl %eax
	ret
//}}}





