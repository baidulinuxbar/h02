#include <toys/const_def.h>
#include <kernel/cstd.h>
//{{{void _ord_int()
void _ord_int(){
	char *ch="ordinary interrupt called";
	_printk(ch);
}//}}}
//{{{void _irq_m_int()
void _irq_m_int(){
	char *ch="IRQ master interrupt called";
	_printk(ch);
}//}}}
//{{{void _irq_s_int()
void _irq_s_int(){
	char *ch="IRQ slave interrupt called";
	_printk(ch);
}//}}}
//{{{void _time_int()
void _time_int(){
	set_cnt();
};//}}}
//{{{void _flp_int()
void _flp_int(){
	char *ch="floppy interrupt called";
	_printk(ch);
};//}}}
//{{{void _hd_int()
void _hd_int(){
	char *ch="hard disk interrupt called";
	_printk(ch);
};//}}}
//{{{void _sys_int()
void _sys_int(){
	char *ch="system called";
	_printk(ch);
};//}}}

	
