/*toys
 *real model const define
 *Copyright (C) 2020-2022 tybitsfox
 */
_LOAD_FROM_HDD	=	1
.ifndef		PROTECT_MODE 
//{{{ real model defined
BOOTSEG			=	0x7c0				#引导代码默认的加载段地址
BOOTADDR		=	0x7c00				#boot代码的加载地址
HEADADDR		=	0x8000				#head代码的加载地址
DISPSEG			=	0xb800				#默认的显示缓冲区地址段
DISP_MOD		=	3					#显示模式为CGA，显示模式3
SMAP			=	0x534d4150			#物理内存的获取标识
#=============8253定时器的设置：
FRQ_8253		=	11930				#工作频率
MOD_8253		=	0x36				#定时器选择：锁存器0,读写MSB/LSB，工作模式3,使用二进制
CMD_PORT_8253	=	0x43				#命令端口号
LCK_PORT_8253	=	0x40				#锁存器端口号
#==============8259a中断控制器：
MASTER_A00_PORT	=	0x20				#主芯片端口号,A0=0,用于发送icw1,ocw2
MASTER_A01_PORT	=	0x21				#主芯片端口号,A0=1,用于发送icw2,icw3,icw4,ocw1
SLAVE_A00_PORT	=	0xa0				#从芯片端口号,A0=0,用于发送icw1,ocw2
SLAVE_A01_PORT	=	0xa1				#从芯片端口号,A0=1,用于发送icw2,icw3,icw4,ocw1
ICW1			=	0x11				#icw1命令：边沿触发中断，多片级联，需要icw4
ICW2_MASTER		=	0x20				#icw2命令：设定主芯片的中断处理起始号：0x20
ICW2_SLAVE		=	0x28				#icw2命令：设定从芯片的中断处理起始号：0x28
ICW3_MASTER		=	4					#icw3命令：设定级联端口，主芯片：4
ICW3_SLAVE		=	2					#icw3命令：设定级联端口，从芯片：2
ICW4			=	1					#icw4命令：设定工作模式：普通全嵌套，非缓冲，非自动结束，8086模式
OCW1_MASK		=	0xff				#ocw1命令：中断屏蔽
OCW1_UNMASK		=	0					#ocw1命令：中断非屏蔽
OCW2			=	0x20				#ocw2命令：非自动结束方式，发送EIO通知中断处理完成
#==============end of 8259a set
//}}}
.else
//{{{segment selector define
KS_CS			=	8
KS_DS			=	0x10
KS_SS			=	0x18
KS_LDT0			=	0x20
KS_TSS0			=	0x28
KS_KSS0			=	0x30
KS_LDT1			=	0x38
KS_TSS1			=	0x40
KS_KSS1			=	0x48
KS_LDT2			=	0x50
KS_TSS2			=	0x58
KS_KSS2			=	0x60

TS_CS			=	0xf
TS_DS			=	0x17
TS_SS			=	0x1f
//{{{system table location & size
IDT_LEN			=	0x7ff
IDT_OFF			=	0
GDT_LEN			=	0x67			#13 *8= 0x68
GDT_OFF			=	0x1000
LDT_LEN			=	0x30			#安装所用，16位对齐 48*6=0x120
LDT_OFF			=	0x2000			
LDT0_LEN		=	0x27
TSS_LEN			=	112				#安装所用，16位对齐 112*6=0x2a0
TSS_OFF			=	0x3000
TSS0_LEN		=	0x67			#103

DMA_LEN			=	0x2400			#18*512
DMA_OFF			=	0x20000			
PDT_LEN			=	0x1000
PDT_OFF			=	0x30000
PDT_MAX_NUM		=	16				#页目录表的数量

PT_SYS_OFF		=	0x40000			#系统内存的页表地址
PT_SYS_MAX_NUM	=	32				#系统内存页表数，128M
#用户页表连续存储于1M位置起始处，计256张，映射1G
PT_USR_OFF		=	0x100000		#用户页表起始地址
PT_USR_MAX_NUM	=	256				#用户页表最大数，1G
#head的最终加载地址，内核代码的运行地址
HEAD_LEN		=	0x7ff			#GDT len
HEAD_OFF		=	0				#GDT addr
#文件系统的加载地址
FS_LEN			=	0xff
FS_OFF			=	0x300000
#任务0的运行空间
TASK0_LEN		=	0xbf
TASK0_OFF		=	0x400000
TASK0_SS_OFF	=	0X4C0000
#任务1的运行空间
TASK1_LEN		=	0x3f
TASK1_OFF		=	0x500000
TASK1_SS_OFF	=	0x540000
#任务2的运行空间
TASK2_LEN		=	0x3f
TASK2_OFF		=	0x580000
TASK2_SS_OFF	=	0x5c0000
#下面的关于堆栈的设置都是基于8M最低内存要求的
KSS_SYS_OFF		=	0x700000		#内核堆栈段起始地址
KSS_USR_OFF		=	0x740000		#任务内核堆栈段起始地址

//}}}
TASK_ENTRY		=	0				#每个任务的入口地址
#堆栈的定义
ESP_LEN			=	0x3ffff			#for stack
KSS_LEN			=	0x3f			#for GDT 256K
DISP_BUFF		=	0xb8000
MEM_GRAN		=	1				#GDT G bit
MEM_REQUEST		=	0x800000		#要求最小内存8M
#SAFE_BUFF		=	0x60000			#18*512,seg=0x7c0
//{{{Segment Type Define
STEXT		=	0x9a					#系统代码段类型字
SDATA		=	0x92					#系统数据段类型字
UTEXT		=	0xfa					#用户代码段
UDATA		=	0xf2					#用户数据段
SLDT		=	0xe2					#LDT段类型字
STSS		=	0xe9					#TSS段类型字
INT_GATE	=	0x8e					#中断门
TRAP_GATE	=	0xef					#陷阱门
TASK_GATE	=	0x85					#任务门	or E5
CALL_GATE	=	0xec					#调用门	or 8C
//}}}

//}}}
.endif
STK_OFF			=	0x3ff				#实模式下堆栈指针sp的初始化位置
STK_SEG			=	0x5000				#实模式下堆栈段地址
MEM_REQUEST		=	0x800000			#运行最小内存要求，8M
#==============
.ifdef	_LOAD_FROM_HDD
LOAD_DRV		=	0x80
MAX_SECT_CNT	=	64					#1-base 63+1
LOAD_SECT_CNT	=	33
SAFE_BUFF		=	0xC000				#seg=0x7c0 (33+1)*512=0xc000
.else
LOAD_DRV		=	0
MAX_SECT_CNT	=	19
LOAD_SECT_CNT	=	17
SAFE_BUFF		=	0x2400				#18*512,seg=0x7c0
.endif

