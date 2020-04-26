/*toys
 *real model const define
 *Copyright (C) 2020-2022 tybitsfox
 */
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
STK_OFF			=	0x3ff				#实模式下堆栈指针sp的初始化位置
STK_SEG			=	0x5000				#实模式下堆栈段地址
MEM_REQUEST		=	0x800000			#运行最小内存要求，8M
#==============
.ifdef	_LOAD_FROM_HDD
LOAD_DRV		=	0x80
MAX_SECT_CNT	=	64					#1-base 63+1
.else
LOAD_DRV		=	0
MAX_SECT_CNT	=	19
.endif
LOAD_SECT_CNT	=	17
SAFE_BUFF		=	0x2400				#18*512,seg=0x7c0

