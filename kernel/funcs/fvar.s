/*toys
 *head：variables and datas file
 *Copyright (C) 2020-2022 tybitsfox
 */
.align 2
stk:			.long	ESP_LEN,KS_SS
_lcount:		.long	0
_flp_flag:		.long	0
bios:			.space	12,0
hd_bios:		.space	16,0
pmem_size:		.long	0
_cursor_pos:	.long	0
minbuf:			.long	0	#for safe
//{{{ table's data
.align 2
#ldt构造函数所用，按入栈顺序排列
ldt_lnk:
	.long	MEM_GRAN,UTEXT,TASK0_LEN,TASK0_OFF	#ldt0 0xf
	.long	MEM_GRAN,UDATA,TASK0_LEN,TASK0_OFF	#ldt0 0x17
	.long	MEM_GRAN,UDATA,KSS_LEN,TASK0_SS_OFF	#ldt0 0x1f

	.long	MEM_GRAN,UTEXT,TASK1_LEN,TASK1_OFF	#ldt1 0xf
	.long	MEM_GRAN,UDATA,TASK1_LEN,TASK1_OFF	#ldt1 0x17
	.long	MEM_GRAN,UDATA,KSS_LEN,TASK1_SS_OFF	#ldt1 0x1f
	
	.long	MEM_GRAN,UTEXT,TASK2_LEN,TASK2_OFF	#ldt2 0xf
	.long	MEM_GRAN,UDATA,TASK2_LEN,TASK2_OFF	#ldt2 0x17
	.long	MEM_GRAN,UDATA,KSS_LEN,TASK2_SS_OFF	#ldt2 0x1f

gdt_lnk:	#same as above
	.long	MEM_GRAN,STEXT,HEAD_LEN,HEAD_OFF	#text	0x8
	.long	MEM_GRAN,SDATA,HEAD_LEN,HEAD_OFF	#data	0x10
	.long	MEM_GRAN,SDATA,KSS_LEN,KSS_SYS_OFF	#stack	0x18

	.long	0,SLDT,LDT0_LEN,LDT_OFF				#ldt0	0x20
	.long	0,STSS,TSS0_LEN,TSS_OFF				#tss0	0x28
	.long	MEM_GRAN,SDATA,KSS_LEN,KSS_USR_OFF	#sstack0	0x30

	.long	0,SLDT,LDT0_LEN,LDT_OFF+LDT_LEN		#ldt1	0x38
	.long	0,STSS,TSS0_LEN,TSS_OFF+TSS_LEN		#tss0	0x40
	.long	MEM_GRAN,SDATA,KSS_LEN,KSS_USR_OFF+0x40000	#sstack0	0x48

	.long	0,SLDT,LDT0_LEN,LDT_OFF+LDT_LEN*2	#ldt1	0x50
	.long	0,STSS,TSS0_LEN,TSS_OFF+TSS_LEN*2	#tss0	0x58
	.long	MEM_GRAN,SDATA,KSS_LEN,KSS_USR_OFF+0x80000	#sstack0	0x60

tss_lnk:
	.long	TSS_OFF,KS_KSS0,PDT_OFF,KS_LDT0						#tss0
	.long	TSS_OFF+TSS_LEN,KS_KSS1,PDT_OFF,KS_LDT1		#tss1
	.long	TSS_OFF+TSS_LEN*2,KS_KSS2,PDT_OFF,KS_LDT2	#tss2
//}}}
.align 2
l_idt:			.word	IDT_LEN
				.long	IDT_OFF
l_gdt:			.word	GDT_LEN
				.long	GDT_OFF
tss0:	.long	0,ESP_LEN,KS_KSS0,0,0,0,0		#link,esp0,ss0,esp12,ss12
		.long	PDT_OFF,TASK_ENTRY,0x200		#CR3,eip,eflags
		.long	0,0,0,0,ESP_LEN,0,0,0			#8 normal registers
		.long	0x17,0xf,0x1f,0x17,0x17,0x17	#6 segment registers
		.long	KS_LDT0,0						#ldt,io-map
.align 4
err_01:	.ascii	"hdd parameters error"
e01_len=.-err_01
err_02:	.ascii	"init error"
e02_len=.-err_02




