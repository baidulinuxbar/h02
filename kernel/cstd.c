#include <toys/const_def.h>
#include <kernel/cstd.h>
static struct SYS_DATA sd_const ={
	8,0x10,0x18,0x20,0x38,0x50,
	0x28,0x40,0x58,0x30,0x48,0x60,
	0xf,0x17,0x1f,0x3ffff,0xb8000,
};
static struct KERN_DATA	kd;
char str[]="hello kernel!";


//{{{void init_kd(BYTE *p)
void init_kd(BYTE *p){
	int i=48;
	_memset((void*)&kd,0,i);
	_memcpy(p,(BYTE *)&kd,i);
	i=kd.pmem;
//	show_ax(i);
};//}}}


//{{{void _cls()
void _cls(){
	__asm__ __volatile__(
	"movw %0,%%es;\n\t"
	"movl %1,%%edi;movl $0x720,%%eax;movl $0x1000,%%ecx;rep stosw;\n\t"
	::"r"(sd_const.ds),"r"(sd_const.disp):"eax","edi","ecx");
	kd.pos=0;
	SETCURSOR;
}//}}}
//{{{size_t _calc_cur(char *ch)
/*传入参数：字符串指针

  返回值：可直接用于设置光标位置的word
 */
size_t _calc_cur(char *ch){
	size_t	pos;
	int len=_strlen(ch);
	int i=kd.pos;
	int j= (i & 0xff);
	int k=(i >> 8) & 0xff;
	if(k > 0)
		j++;
	i=len/80;
	if((len % 80) > 0)
		i++;
	if((i+j) > 24)
	{
		_cls();kd.pos=0;
		pos=(len/80);
		if((len % 80) > 0)
			pos+=(len % 80)*0x100;
	}
	else
	{
		pos=kd.pos;
		if((pos / 0x100) > 0)
		{pos++;pos=(pos & 0xff);}
		pos+=(len/80);
		pos+=(len%80)*0x100;
	}
	i=kd.pos;
	j=( i & 0xff)*160;
	k=(i >> 8) & 0xff;
	if(k > 0)
		j+=160;
	kd.pos=pos;
	return (size_t)j;
};//}}}
//{{{void _printk(char *ch)
/*注意：该函数没有实现对自身含有换行回车字符串的换行处理*/
void _printk(char *ch){
	int len=_strlen(ch);
	if(len == 0)
		return;
	size_t pos=_calc_cur(ch);
	__asm__ __volatile__(
		"movw $0x10,%%ax;movw %%ax,%%es;\n\t"
		"movl %1,%%esi;addl $0xb8000,%%edi;\n\t"
		"movb $0x7,%%ah;1:;lodsb;stosw;loop 1b;\n\t"
		::"c"(len),"p"(ch),"D"(pos):"eax");
	SETCURSOR;
};//}}}
//{{{int _in_main()
int _in_main(){
	_printk(str);
	_printk(str);
	delay(20);
	show_ax(kd.tcnt);
	return 0;
};//}}}
//{{{int get_cnt()
int get_cnt(){return kd.tcnt;};//}}}
//{{{void set_cnt()
void set_cnt(){kd.tcnt++;};//}}}




