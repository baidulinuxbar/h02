.code16
.include "defconst.s"
.text
	jmp $BOOTSEG,$go
go:
	mov %cs,%ax
	mov %ax,%ds
	mov %ax,%es
	lss	stk,%sp
	mov %sp,%bp
	call check_set_disp
	call get_flp_para
	call get_phy_mem
	jnc 1f
	mov $0x1234,%ax
	jmp .
1:
	push $LOAD_DRV			#para1:head num & driver num
	push $2					#para2:cylinder num & sector num ready to read
	push $LOAD_SECT_CNT		#para3:sector numbers wants to read
	call load_head
	jnc 2f
	mov $0xabcd,%ax
	jmp .
2:
	mov %bp,%sp
	lea msg,%ax
	push %ax
	mov $len,%ax
	push %ax
	call show_msg
	mov %bp,%sp
	call check_mem
	push %es
	les stk,%di
	add $33,%di
	movl $0,%eax
	mov _cursor_pos,%ax
	stosl
	pop %es
	call setup_8253
	call reset_8259a
	lgdt l_gdt
	smsw %ax
	or $1,%ax
	lmsw %ax
	jmp $8,$0x8000

stk:	.word	STK_OFF,STK_SEG,0
_cursor_pos:	.word	0

//{{{cls	清屏函数
/*传入参数：无
  作用：清屏，并重置光标位置:0
  
  返回值：无
 */
cls:
	mov $DISPSEG,%ax
	mov %ax,%es
	mov $0,%di
	mov $0x1000,%cx
	mov $0x720,%ax
	rep stosw
	movw $0,_cursor_pos
	call set_cursor
	ret
//}}}
//{{{set_cursor	设置光标函数
/*传入参数：无，依据系统变量_cursor_pos设定光标位置
  作用：设定当前光标位置

  返回值：无
 */	
set_cursor:
	mov _cursor_pos,%bx
	mov $0,%ax
	xchgb %bl,%al
	mov $80,%cx
	mulb %cl
	xchgb %bl,%bh
	add %ax,%bx
	mov $0xf,%ax
	mov $0x3d4,%dx
	outb %al,%dx
	inc %dx
	movb %bl,%al
	outb %al,%dx
	mov $0xe,%ax
	mov $0x3d4,%dx
	outb %al,%dx
	movb %bh,%al
	inc %dx
	outb %al,%dx
	ret
//}}}
//{{{check_set_disp	测试，设置显示模式
/*传入参数：无
  作用：测试当前的显示模式是否为：CGA 模式3,不是则设置为CGA 模式3
  		并清屏.

  返回值：无
 */	
check_set_disp:
	push %ds
	mov $0x40,%ax
	mov %ax,%ds
	mov $0x49,%si
	lodsb
	cmpb $DISP_MOD,%al
	je 1f
	mov $3,%ax
	int $0x10
1:	
	pop %ds
	call cls
	ret
//}}}
//{{{get_flp_para	取得软驱的bios参数
/*传入参数：无
  作用：取得bios设置的软驱参数，供我的软驱驱动使用，共12字节，保存在
  		stack上方位置缓冲区.

  返回值：无		
 */
get_flp_para:
	push %ds
	les stk,%di
	inc %di
	mov $0,%ax
	mov %ax,%ds
	mov $0x78,%bx		#0x1E
	mov (%bx),%si
	mov 2(%bx),%ax
	mov %ax,%ds
	mov $12,%cx
	rep movsb			#存储了软驱参数	12字节
	mov $0,%ax
	mov %ax,%ds
	mov $0x104,%bx		#int 0x41,0x46
	mov (%bx),%si
	mov 2(%bx),%ax
	mov %ax,%ds
	mov $16,%cx
	rep movsb			#存储了第一硬盘的参数 16字节
	pop %ds
	ret
//}}}
//{{{get_phy_mem	取得物理内存
/*传入参数：无
  作用：取得实际的物理内存大小，并保存至软驱参数之后。

  返回值：CF error if cf=1。
 */
get_phy_mem:
	push %ds
	pop %es
	movl $SMAP,%edx
	movl $20,%ecx
	movl $0,%ebx
	movl $0,%esi
1:
	movl $0x200,%edi
	movl $0xe820,%eax
	int $0x15
	jc 2f
	movl 8(%edi),%eax
	addl %eax,%esi
	cmpl $0,%ebx
	jne 1b
	jmp 3f
2:
	movl $0,%esi
3:
	testl $0x8000,%esi
	jz 4f
	addl $0x8000,%esi
4:
	xorl %edi,%edi
	les stk,%di
	add $29,%di
	movl %esi,%eax
	stosl
	ret
//}}}
//{{{load_head	加载head
/*传入参数：驱动器号，磁头号，柱面号，起始扇区号（1-base），读取的扇区数
  传入方式：堆栈，其中：
  para1（esp+8）：磁头，驱动器号;hi 8bits = head low 8bits = driver (flp A:0)
  para2（esp+6）：柱面号，起始扇区号（1-base），hi 8bits = low 8bits of cylinder
  				  low 8bits of 2 hi bits = hi 2 bits of cylinder
			  	  low 8bits of 5 low bits = sector number(1-base)
  para3（esp+4）：待读取的扇区数，must less than 18

  返回值：CF set if error
 */
load_head:
	push %bp
	mov %sp,%bp
	push %ds
	pop %es
	clc
	mov 8(%bp),%dx
	cmpb $1,%dh
	jbe 1f
	jmp 8f
1:
	cmpb $0x80,%dl
	jbe 2f
	jmp 8f
2:
	mov 6(%bp),%cx
	cmpb $80,%ch
	jb 3f
	jmp 8f
3:
	cmpb $MAX_SECT_CNT,%cl
	jb 4f
	jmp 8f
4:
	mov 4(%bp),%ax
	cmpb $MAX_SECT_CNT,%al
	jbe 5f
	jmp 8f
5:
	mov $2,%ah
	mov $0x200,%bx			#load to 0x8000
	int $0x13
	jmp 9f
8:
	stc
9:
	mov %bp,%sp
	pop %bp
	ret
//}}}
//===================boot sign==================
.org	510
.word	0xaa55
//==============================================
//{{{setup_8253		8253定时器的设置，使用定时器0,系统脉搏为10ms（1/100秒）
/*固定设置，无需参数*/
setup_8253:
	cli
	mov $MOD_8253,%ax		#使用定时器0,模式3,读写LSB/MSB,二进制
	mov $CMD_PORT_8253,%dx
	outb %al,%dx
	jmp .+2
	jmp .+2
	mov $FRQ_8253,%ax
	mov $LCK_PORT_8253,%dx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movb %ah,%al
	outb %al,%dx
	sti
	ret
//}}}
//{{{reset_8259a	重设中断控制器
/*固定设置，无需参数。
  重新设定中断号为0x20,0x28,使用icw4,8086兼容模式，需要从芯片，非缓冲，非自动结束
 */
reset_8259a:
	cli
	mov $ICW1,%ax
	mov $MASTER_A00_PORT,%dx
	outb %al,%dx			#icw1 master
	jmp .+2
	mov $SLAVE_A00_PORT,%dx
	outb %al,%dx			#icw1 slave
	jmp .+2
	mov $ICW2_MASTER,%ax
	mov $MASTER_A01_PORT,%dx
	outb %al,%dx			#icw2 master
	jmp .+2
	mov $ICW2_SLAVE,%ax
	mov $SLAVE_A01_PORT,%dx
	outb %al,%dx			#icw2 slave
	jmp .+2
	mov $ICW3_MASTER,%ax
	mov $MASTER_A01_PORT,%dx
	outb %al,%dx			#icw3 master
	jmp .+2
	mov $ICW3_SLAVE,%ax
	mov $SLAVE_A01_PORT,%dx
	outb %al,%dx			#icw3 slave
	jmp .+2
	mov $ICW4,%ax
	mov $MASTER_A01_PORT,%dx
	outb %al,%dx			#icw4 master
	jmp .+2
	mov $SLAVE_A01_PORT,%dx
	outb %al,%dx			#icw4 slave
	jmp .+2
	mov $OCW1_MASK,%ax
	mov $MASTER_A01_PORT,%dx
	outb %al,%dx			#ocw1 master	mask all register
	jmp .+2
	mov $SLAVE_A01_PORT,%dx
	outb %al,%dx			#ocw1 slave		mask all register
	ret
//}}}
//{{{calc_cursor	计算光标位置，使用_cursor_pos
/*该函数主要用于计算待输入字符串与原光标位置是否超出一屏，如超出，则清屏
  否则_cursor_pos不变。
   传入参数：待显示字符串的长度
  
  返回值：ax=显示输出的行号（0-base）*160,即显示缓冲区的显示地址
 */
calc_cursor:
	push %bp
	mov %sp,%bp
	mov 4(%bp),%ax
	push %cs
	pop %ds
	mov _cursor_pos,%bx #bl保存原行数，bh保存原列数
	mov $80,%cx
	divb %cl			#al保存行数，ah保存列数
	cmpb $0,%ah
	je 2f
	addb $1,%al			#实际要显示的行数
2:
	addb %bl,%al		#测试显示新串后是否超出一页？
	cmpb $24,%al
	jbe 3f
	call cls
3:
	mov _cursor_pos,%bx
	cmpb $0,%bh
	je 4f
	addb $1,%bl
4:
	mov $0,%ax
	movb %bl,%al
	mov $0,%dx
	mov $160,%cx
	mulb %cl			#ax中保存了显示缓冲地址
9:	
	mov %bp,%sp
	pop %bp
	ret
//}}}	
//{{{show_msg	测试函数，显示信息
/*传入参数：string addr,string len
  para1 6（esp）：addr
  para2 4（esp）：len

  返回值：无
  逻辑实现：1、调用calc_cursor计算光标，若CF=1则不显示字符串
  			2、使用calc_cursor的返回值设置显示位置，显示输出字符串
			3、修改_cursor_pos,并且调用set_cursor移动光标。
 */	
show_msg:
	push %bp
	mov %sp,%bp
	mov 4(%bp),%ax
	cmp $0x100,%ax			#字符串长度最大255字节
	jae 9f
	mov 6(%bp),%si			#string buffer
	mov 4(%bp),%cx			#string len
	push %cx
	call calc_cursor
	pop %cx
	mov %ax,%di
	mov $DISPSEG,%ax
	mov %ax,%es
	mov $0xb00,%ax
1:
	lodsb
	stosw
	loop 1b
	mov 4(%bp),%ax
	mov $0,%dx
	mov $80,%cx
	divb %cl
	mov _cursor_pos,%bx
	cmpb $0,%bh
	je 2f
	inc %ax
2:
	addb %bl,%al
	mov %ax,_cursor_pos
	call set_cursor
9:	
	mov %bp,%sp
	pop %bp
	ret
//}}}	
//{{{check_mem	检查物理内存大小
/*传入参数：无

  返回值： 若内存数小于最低要求则，中断执行
  逻辑实现：1、检查获取的物理内存大小
  			2、满足要求则本函数退出，继续执行
			3、否则，调用show_msg函数，显示错误信息，并终止
 */
check_mem:
	push %ds
	lds stk,%si
	add $29,%si
	lodsl
	pop %ds
	cmpl $MEM_REQUEST,%eax
	jae 3f
	lea err_msg,%ax
	push %ax
	mov $err_len,%ax
	push %ax
	call show_msg
	pop %ax
	pop %ax
	jmp .
3:	
	ret
//}}}

err_msg:	.ascii "Physical memory require 8M at least"
err_len = .-err_msg
msg:	.ascii	"booting.........................................[ok]"
len=.-msg
l_gdt:	.word	47
		.long	BOOTADDR+gdt
gdt:	.word	0,0,0,0
		.word	0x7ff,0,0x9a00,0x00c0			#0x8	text
		.word	0x7ff,0,0x9200,0x00c0			#0x10	data
		.word	0x3f,0,0x9270,0x00c0			#0x18	stack
		.space	16,0
.org	1020
.ascii	"tian"

