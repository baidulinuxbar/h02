/*OK! my kernel, and call it.... tyos? tos? ...:
 *my kernel: toys~ right! that's a good name! ;-)
 *include/kern/kc1.h
 *Copyright (c) 2020,2021 tybitsfox
 *
 */
#ifndef	_TOYS
#define	_TOYS		0x1343BE6
//{{{defined
#define	BYTE		unsigned char
#define WORD		unsigned short
#define size_t		unsigned int
#define NULL		(void *)0
#define show_ax(x)	__asm__("movl %0,%%eax;jmp .;"::"r"(x):"eax")
//define segment type
#define STEXT		0x9a
#define	SDATA		0x92
#define	UTEXT		0xfa
#define UDATA		0xf2
#define SLDT		0xe2
#define STSS		0xe9
#define INT_GATE	0x8e
#define TRAP_GATE	0xef
#define TASK_GATE	0x85
#define CALL_GATE	0xec
//}}}
//disable auto extend bits
#pragma pack(1)
//{{{ sys_data	传承自汇编的定义
struct SYS_DATA
{
	WORD	cs;
	WORD	ds;
	WORD	ss;
	WORD	ldt[3];		/*local describe table */
	WORD	tss[3];		/*task status segment */
	WORD	kss[3];		/*task user ss */
	WORD	ucs;		/*task cs */
	WORD	uds;
	WORD	uss;
	long	esp;		/*esp len */
	long	disp;
};
//}}}
//{{{ sys_locate 各种系统表（IDT,GDT,LDT,TSS,PDT,PT）的定位
struct SYS_LOCATE
{
	long	idt_len;
	long	idt_off;
	long	gdt_len;
	long	gdt_off;
	long	ldt_len;
	long	ldt_off[3];
	long	tss_len;
	long	tss_off[3];
	long	dma_len;
	long	dma_off;
	long	pdt_len;
	long	pdt_off;
	long	pdt_max_num;		//最大页目录数
	long	pt_sys_off;
	long	pt_sys_max_num;		//最大系统内存页表数
	long	pt_usr_off;			//最大用户内存页表数
	long	pt_use_max_num;
//	long	disp_len;			//GDT len
	long	disp_off;
	long	task_entry;			//任务入口地址
	long	head_len;
	long	head_off;			//内核代码最终加载位置
	long	esp_len;			//for stack
	long	ss_len;				//for GDT
	long	ss_sys_off;			//内核堆栈
	long	ss_usr_off;			//任务的系统堆栈
	long	ss_usr_max;			//最大任务系统堆栈数
	long	task_len;			//for GDT
	long	task_off[3];		//task address
	long	task_ss[3];			//usr stack
	BYTE	mem_gran;			//GDT G bit
	long	mem_request;		//最小内存要求
	long	safe_buf;			//安全缓冲区地址
};
static struct SYS_LOCATE _slo={
0x7ff,0,0x67,0x1000,	/*idt,gdt*/
0x30,0x2000,0x2030,0x2060,		/*ldt*/
112,0x3000,0x3070,0x30e0,		/*tss*/
0x2400,0x20000,0x1000,0x30000,16,0x40000,32,0x100000,256,	/*dma,pdt,pt*/
/*disp,esp,ss,sysss,usrss,maxss,tasklen */
0xb8000,0,0x7ff,0,0x3ff,0x3f,0x700000,0x740000,3,0x3f,
0x400000,0x500000,0x580000, /*3 task off */
0x4c0000,0x540000,0x5c0000, /*3 task's usr ss*/
1,0x800000,0x600000,		/*mem_gran,request mem,safe buf*/
};
//}}}
//{{{kern_data 系统变量及参数表定义
struct KERN_DATA
{
	long	tcnt;			/*time counter */
	long	flp_flag;		/*flp int flag */
	BYTE	fbbios[12];		/*flp para */
	BYTE	hdbios[16];		/*hdd para */
	long	pmem;			/*physical mem */
	long	pos;			/*cursor pos */
};
//}}}
#pragma pack()

#endif


