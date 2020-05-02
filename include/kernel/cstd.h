#ifndef		SETCURSOR
#define SETCURSOR	__asm__("movl %0,%%eax;andl $0xff,%%eax;movl $80,%%ecx;mulb %%cl;shrl $8,%%ebx;addl %%eax,%%ebx;\n\t" \
		"movb $0xf,%%al;movw $0x3d4,%%dx;outb %%al,%%dx\n\t" \
		"movb %%bl,%%al;incw %%dx;outb %%al,%%dx;movb $0xe,%%al;decw %%dx;\n\t"\
		"outb %%al,%%dx;movb %%bh,%%al;incw %%dx;outb %%al,%%dx\n\t"::"b"(kd.pos):"eax","ecx","edx");
#define _memcpy(s,d,len)	__asm__("movl %0,%%esi;movl %1,%%edi;rep movsb"::"p"(s),"p"(d),"c"(len):"eax","esi","edi");
#define _memset(s,i,len)	__asm__("movl %0,%%edi;rep stosb"::"p"(s),"a"(i),"c"(len):"edi");
#define _strlen(s)		({register int i;__asm__("movl $0x10001,%%ecx;movb $0,%%al;repne scasb;negw %%cx;movl %%ecx,%%eax":"=a"(i):"D"(s):"ecx");i;});
#define delay(t)	__asm__ __volatile__("andl $0xff,%%eax;int $0x80;"::"a"(t));
#endif


void init_kd(BYTE *p);
void _cls();
size_t _calc_cur(char *ch);
void _printk(char *ch);
int _in_main();
int get_cnt();
void set_cnt();
