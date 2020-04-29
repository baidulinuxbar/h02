/*
Author:tybitsfox
2020-4-17
 */
//{{{----------------HDD PORT DEFINE------------------
HD_PORT_DATA		=	0x1F0		#read/write  fetch data
HD_PORT_ERR			=	0X1F1		#read	get err code
HD_PORT_PCOM		=	0X1F1		#write  precomp
HD_PORT_SECT_CNT	=	0X1F2		#read/write sector counts
HD_PORT_SECT_NUM	=	0X1F3		#read/write sector index
HD_PORT_LTRACK		=	0X1F4		#read/write cylinder low 8bits
HD_PORT_HTRACK		=	0X1F5		#read/write cylinder hi 8bits
HD_PORT_DRV_HEAD	=	0X1F6		#read/write driver,head(101dhhhh)
HD_PORT_STATUS		=	0X1F7		#read  get status
HD_PORT_COMMAND		=	0X1F7		#write send command
HD_PORT_CTRL		=	0X3F6		#write control register
HD_PORT_INDATA		=	0X3F7		#read 
//}}}
//{{{----------------HDD EXEC ERROR-------------------------
#下面的命令获取自0x1f1错误寄存器，但必须在主状态寄存器0x1f7的位0置1时才有效
HD_ERR_NONE			=	0X1			#no error OR LOST SIGN ERR
HD_ERR_CTRL			=	0X2			#control error OR TRACK 0 ERR
HD_ERR_BUFF			=	0X3			#buffer error 	OR NONE
HD_ERR_ECC			=	0X4			#ecc error OR	ABORT COMMAND
HD_ERR_PROC			=	0X5			#processor err OR NONE
HD_ERR_ID			=	0X10		#none OR MISS ID
HD_ERR_ECCS			=	0X40		#none or ECC WRONG
HD_ERR_SECT			=	0x80		#none OR BAD SECTOR
//}}}
//{{{----------------HDD MAIN STATUS------------------------
#这是主状态寄存器0x1f7读操作时的状态值定义
HD_STAT_ERR			=	1	#exec command error
HD_STAT_IDX			=	2		#recive index
HD_STAT_ECC			=	4		#ecc check error
HD_STAT_DRQ			=	8		#data request,can access data port!
HD_STAT_SEEK		=	0x10	#seek track over
HD_STAT_WRERR		=	0x20	#driver fault
HD_STAT_READY		=	0X40	#driver ready
HD_STAT_BUSY		=	0x80	#control register is busy
//}}}
//{{{----------------HDD COMMAND-----------------------------
#这里是所有命令的定义
HD_CMD_RST			=	0X10	#reset command
HD_CMD_READ			=	0X20	#read sector
HD_CMD_WRITE		=	0x30	#write sector
HD_CMD_CHK_SECT		=	0X40	#verify sector
HD_CMD_FORMAT		=	0x50	#format a track
HD_CMD_INIT			=	0X60	#init control
HD_CMD_SEEK			=	0x70	#seek track
HD_CMD_DIAG			=	0X90	#diagnose control 诊断控制器
HD_CMD_SPEC			=	0X91	#specify parameters for dirver
//}}}
//{{{----------------HDD CONTROL BITS MASK-------------------
#这里定义的是硬盘控制器0x3f6控制字节的定义，该字节取自于硬盘控制参数表偏移0x8处
HD_CTL_NONE			=	1		#no use
HD_CTL_IRQ_OFF		=	2		#close irq
HD_CTL_RESET		=	4		#enable reset
HD_CTL_HEAD_MORE	=	8		#if heads more than 8 then set 1
HD_CTL_CYL_MAP		=	32		#IF cylinder+1 has bad map then set 1
HD_CTL_ECC_DIS		=	64		#disable ecc
HD_CTL_REACCESS		=	128		#disable re-access
#default contro byte:
HD_CTL_DEFAULT		=	0xC8	#默认向0x3f6发送的控制字节
#HD_CTL_DEFAULT		=	0x8		#默认向0x3f6发送的控制字节
//}}}
//{{{----------------HDD INT ABOUT-----------------
#这里定义的中断相关的常量
HD_INT_READY		=	0		#can be exec
HD_INT_SUCC			=	1		#finished with no error
HD_INT_ERR			=	2		#with error
//}}}
//{{{----------------Variables Define--------------
#16字节的硬盘参数表
hdd_trk:			.word	0
hdd_head:			.byte	0
					.word	0
hdd_precomp:		.word	0		#mul 4
hdd_ecc:			.byte	0
hdd_ctrl:			.byte	0
					.space	3,0		#no use
hdd_land:			.word	0
hdd_sect_peer_trk:	.byte	0
					.byte	0
//}}}
//{{{----------------param for running--------------
hd_drv:		.byte 0		#启动器号
hd_head:	.byte 0		#磁头号
hd_bsect:	.byte 35	#起始扇区号
hd_csect:	.byte 0		#扇区数
hd_htrk:	.byte 0		#柱面高字节
hd_ltrk:	.byte 0		#柱面低字节
hd_cmd:		.byte 0		#要执行的命令
hd_data_buf:	.long 0		#缓冲区地址
hd_last_err:	.byte 0		#错误代码
hd_fin_int:	.byte 0		#中断完成：成功：1；错误：2，调用之前：清零
//}}}


