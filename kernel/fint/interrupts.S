/*toys
 *kernel：interrupt interface file
 *Copyright (C) 2020-2022 tybitsfox
 */
//#include <kernel/entry.h>
#define	KS_DS	0x10
#define CALL_ENTRY(X)	 _/**/X

//{{{macro defined
#define ENTRY(N)		 \
	.globl N;	\
	N/**/:;		\
	pusha;\
	push %ds;	\
	push %es;	\
	movl $KS_DS,%eax; \
	movw %ax,%ds; \
	movw %ax,%es; \
	call CALL_ENTRY(N); \
	pop %es;	\
	pop %ds;	\
	popa; \
	iret 

#define ENTRY_M(N)		 \
	.globl N; \
	N/**/:;		\
	pusha;\
	push %ds;	\
	push %es;	\
	movl $KS_DS,%eax; \
	movw %ax,%ds; \
	movw %ax,%es; \
	call CALL_ENTRY(N); \
	movl $0x20,%eax; \
	outb %al,$0x20; \
	pop %es;	\
	pop %ds;	\
	popa; \
	iret

#define ENTRY_S(N)		 \
	.globl N; \
	N/**/:;		\
	pusha;\
	push %ds;	\
	push %es;	\
	movl $KS_DS,%eax; \
	movw %ax,%ds; \
	movw %ax,%es; \
	call CALL_ENTRY(N); \
	movl $0x20,%eax; \
	outb %al,$0xa0; \
	jmp .+2; \
	outb %al,$0x20; \
	pop %es;	\
	pop %ds;	\
	popa; \
	iret

#define SYS_CALL(N)		\
	.globl N;	\
	N/**/:;		\
	pushl %ebp;	\
	push %ds;	\
	push %es;	\
	movl %esp,%ebp;	\
	pushl %edx; \
	movl $KS_DS,%edx; \
	movw %dx,%ds; \
	movw %dx,%es; \
	pushl %ecx; \
	pushl %ebx; \
	pushl %eax; \
	call CALL_ENTRY(N); \
	movl %ebp,%esp; \
	pop %es;	\
	pop %ds;	\
	popl %ebp;	\
	iret 


//}}}

ENTRY(ord_int)
ENTRY_M(irq_m_int)
ENTRY_S(irq_s_int)
ENTRY_M(time_int)
ENTRY_M(flp_int)
ENTRY_S(hd_int)
SYS_CALL(sys_int)

