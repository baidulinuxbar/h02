//---------------------defined for floppy driver access------------------
fdc_mt:					.byte	0				#multitrack,多磁道=1，	range:0-1
fdc_mfm:				.byte	1				#modified frequency modulation,双密度=1，range:0-1
fdc_sk:					.byte	1				#skip，跳过删除数据的扇区=1,range:0-1
fdc_drv:				.byte	0				#flp driver				range:0-3
fdc_head:				.byte	0				#head number			range:0-1
fdc_dma:				.byte	1				#use dma if set 1		range:0-1
fdc_trk:				.byte	0				#cylinder or track num	range:0-79
fdc_bsec:				.byte	0				#begin sector 1-base	range:1-18
fdc_csec:				.byte	0				#sector count			range:1-18
fdc_cmd:				.byte	0				#FDC command
fdc_srt:				.byte	4				#step rate time			range:1-16
fdc_hlt:				.byte	8				#head load time			range:0-0x7f
fdc_hut:				.byte	1				#head unload time		range:1-0xf
fdc_dma_off:			.long	0				#dma buffer address		range:less than 20 bits
fdc_dma_cnt:			.word	0				#dma bytes number for trans 
//shadow of bios
fdc_type:				.word	0				#floppy driver type
fdc_motor_shut_down:	.byte	0				#motor shutdown needs count
fdc_bytes_peer_sect:	.byte	0				#bytes peer sector		range:0-3
fdc_sect_peer_track:	.byte	0				#sectors peer track
fdc_gap:				.byte	0				#GAP length
fdc_data_length:		.byte	0				#data length
fdc_fmt_need_time:		.byte	0				#format needs time
fdc_fmt_fill:			.byte	0				#format fill byte
fdc_head_put_time:		.byte	0				#head put down needs time(ms)
fdc_motor_on_time:		.byte	0				#motor on need time(1/8second)
//fdc status buffer
fdc_stat_buff:			.byte	8,0				#fdc return status 
//------------------------const for floppy driver-----------------------------
//port for DFC
FDC_PORT_DOR			=	0x3f2
FDC_PORT_MSR			=	0x3f4		#status
FDC_PORT_FIFO			=	0x3f5		#data 
FDC_PORT_CTRL			=	0x3f7
//command for FDC
FDC_CMD_READ_TRACK		=	2
FDC_CMD_SPECIFY			=	3
FDC_CMD_CHECK_STAT		=	4
FDC_CMD_WRITE_SECT		=	5
FDC_CMD_READ_SECT		=	6
FDC_CMD_CALIBRATE		=	7
FDC_CMD_CHECK_INT		=	8
FDC_CMD_WRITE_DEL_S		=	9
FDC_CMD_READ_ID_S		=	0xa
FDC_CMD_READ_DEL_S		=	0xc
FDC_CMD_FORMAT_TRACK	=	0xd
FDC_CMD_SEEK			=	0xf







