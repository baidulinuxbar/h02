/*硬盘驱动
测试用的硬盘设置为：20cylinder,64sector,16head,total 9.9M
 
Author:tybitsfox
2020-4-17
 */
//{{{init_hdd_para	参数初始化函数
/*传入参数：驱动器号，磁头号，起始扇区号，扇区数，柱面号，缓冲区地址
  传入方式：堆栈
  			20(%ebp): 缓冲区地址
			16(%ebp): hi驱动器号，lo磁头号
			12(%ebp): hi起始扇区号，lo扇区数
			8(%ebp) : 柱面号

  返回值：CF cf=1 error,cf=0 success
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
	pop %es
	pop %ds
	movl 8(%ebp),%eax
	cmpw hdd_trk,%ax
	jae 1f
	movb %al,hd_ltrk
	movb %ah,hd_htrk
	movl 12(%ebp),%eax
	addb %ah,%al
	decb %al
	cmpb hdd_sect_peer_trk,%al
	ja 1f
	movl 12(%ebp),%eax
	movb %ah,hd_bsect
	movb %al,hd_csect
	movl 16(%ebp),%eax
	cmpb $1,%ah				#onle support master & slave hdd:0,1
	ja 1f
	cmpb hdd_head,%al
	ja 1f
	movb %ah,hd_drv
	movb %al,hd_head
	movl 20(%ebp),%eax
	movl %eax,hd_data_buf
	clc
	jmp 2f
1:
	stc
2:
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





