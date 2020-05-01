#include <toys/const_def.h>
static struct KERN_DATA	kd;
#define SETCURSOR(x)	__asm__("movb $0xf,%%al;movw $0x3d4,%%dx;outb %%al,%%dx\n\t" \
		"movb %%bl,%%al;incw %%dx;outb %%al,%%dx;movb $0xe,%%al;decw %%dx;\n\t"\
		"movb %%bh,%%al;incw %%dx;outb %%al,%%dx\n\t"::"b"(x):"eax","edx");
#define _memcpy(s,d,len)	__asm__("movl %0,%%esi;movl %1,%%edi;rep movsb"::"p"(s),"p"(d),"c"(len):"eax","esi","edi");
#define _memset(s,i,len)	__asm__("movl %0,%%edi;rep stosb"::"p"(s),"a"(i),"c"(len):"edi");
#define _strlen(s)		({register int i;__asm__("movl $0x10001,%%ecx;movb $0,%%al;repne scasb;negw %%cx;movl %%ecx,%%eax":"=a"(i):"D"(s):"ecx");i});
//{{{void init_kd(BYTE *p)
void init_kd(BYTE *p){
	int i=48;
	_memset((void*)&kd,0,i);
	_memcpy(p,(BYTE *)&kd,i);
	i=kd.pmem;
	show_ax(i);
};//}}}


//{{{size_t _calc_cur(char *ch)
size_t _calc_cur(char *ch){
	size_t pos;
	pos=12;
	return pos;
};//}}}








