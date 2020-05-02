#define	KS_DS	0x10
#define CALL_ENTRY(X)	 _/**/X

//{{{macro defined
#define ENTRY(N)		 \
	.globl N;	\
	N/**/:;		\
	pusha;\
	movl $KS_DS,%eax; \
	movw %ax,%ds; \
	movw %ax,%es; \
	call CALL_ENTRY(N); \
	popa; \
	ret 

#define ENTRY_M(N)		 \
	.globl N; \
	N/**/:;		\
	pusha;\
	movl $KS_DS,%eax; \
	movw %ax,%ds; \
	movw %ax,%es; \
	call CALL_ENTRY(N); \
	popa; \
	iret; \
	movl $0x20,%eax; \
	outb %al,$0x20; \
	popa; \
	iret

#define ENTRY_S(N)		 \
	.globl N; \
	N/**/:;		\
	pusha;\
	movl $KS_DS,%eax; \
	movw %ax,%ds; \
	movw %ax,%es; \
	call CALL_ENTRY(N); \
	popa; \
	iret; \
	movl $0x20,%eax; \
	outb %al,$0xa0; \
	jmp .+2; \
	outb %al,$0x20; \
	popa; \
	iret
//}}}


