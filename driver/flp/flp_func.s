//{{{ About floppy disk driver
/*floppy disk driver
Copyright © 2020 - 2022 tybitsfox, All Rights Reserved
关于参数传递的方法，一开始我想按照c的做法，使用堆栈传递。但是汇编编译器是不
能自动保持堆栈平衡的，这样在调用时就要添加额外的代码来保证函数调用的堆栈平
衡。因此，在汇编下并且传递参数不是很多的情况下还是通过寄存器传递更简洁和方
便。
--------------------------------------------------------------------------
测试证明：不是所有的FDC命令都会引发irq6中断的，
例如：检测驱动器命令（index=4）不会引发中断，当然还有检测中断命令（index=8）本身，
定义基准参数的命令（index=3）测试不会引发中断
目前测试的上面几个命令是不需要wait_for_irq及check_int操作的，
At the beginning of the result phase of the commands:
        read sector
        read deleted sector
        write sector
        write deleted sector
        read track
        format track
        read sector ID
        verify
        
        After completion of the following commands without a result phase:
        calibrate drive
        seek
        seek relative
        
        For data exchange between main memory and controller when interrupt-driven data exchange 
        is active and the controller is not using DMA.
--------------------------------------------------------------------------
motor_on，motor_off和fdc_reset的关系：
马达启动需要指定：驱动器号，DMA是否使用，同时设置reset标志
马达关闭只需要设置reset标志
而软驱控制器的重置则是发送空字节（全设为0）禁用FDC，然后在发送reset和DMA使
用的组合标志，等待中断响应够读取所有四个驱动器的状态字。然后在对FDC进行初始
化设置：
1、发送传输速率（00：500kbps,01:250k,10:300k,11:1m）至CCR（0x3f7）端口，
2、发送定义基本参数命令（3）及参数：step rate=3ms,unload time=240ms,
load time=16ms,是否使用DMA

-------------------------------------------------------------------------- */
#learn from linux kernle 1.33:
#static struct {
#	struct floppy_drive_params params;
#	const char *name; /* name printed while booting */
#} default_drive_params[]= {
/* NOTE: the time values in jiffies should be in msec!
 CMOS drive type
  |     Maximum data rate supported by drive type
  |     |   Head load time, msec
  |     |   |   Head unload time, msec (not used)
  |     |   |   |     Step rate interval, usec
  |     |   |   |     |       Time needed for spinup time (jiffies)
  |     |   |   |     |       |      Timeout for spinning down (jiffies)
  |     |   |   |     |       |      |   Spindown offset (where disk stops)
  |     |   |   |     |       |      |   |     Select delay
  |     |   |   |     |       |      |   |     |     RPS
  |     |   |   |     |       |      |   |     |     |    Max number of tracks
  |     |   |   |     |       |      |   |     |     |    |     Interrupt timeout
  |     |   |   |     |       |      |   |     |     |    |     |   Max nonintlv. sectors
  |     |   |   |     |       |      |   |     |     |    |     |   | -Max Errors- flags */
#{{4,  500, 16, 16, 4000, 4*HZ/10, 3*HZ, 10, SEL_DLY, 5,  83, 3*HZ, 20, {3,1,2,0,2}, 0,
#      0, { 7, 4,25,22,31,21,29,11}, 3*HZ/2, 7 }, "1.44M" }, /*3 1/2 HD*/

#struct floppy_struct {
#	unsigned int	size,		/* nr of sectors total */
#			sect,		/* sectors per track */
#			head,		/* nr of heads */
#			track,		/* nr of tracks */
#			stretch;	/* !=0 means double track steps */
#	unsigned char	gap,		/* gap1 size */
#			rate,		/* data rate. |= 0x40 for perpendicular */
#			spec1,		/* stepping rate, head unload time */
#			fmt_gap;	/* gap2 size */
#	const char	* name; /* used only for predefined formats */
#};

#static struct floppy_struct floppy_type[32] = {
#	{ 2880,18,2,80,0,0x1B,0x00,0xCF,0x6C,"H1440" },	/*  7 1.44MB 3.5"   */
#};
#static struct floppy_struct * floppy = floppy_type;
/*
--------------------so~easy todo is-------------------
srt/1000	(usec->msec)				range: 0-0xf
hlt/2		(head load time)			range: 0-0x7f
hut/16		(head unload time)			range: 1-0xf

-------------before calc,the range is----------------
 * srt: 1000 to 16000 in microseconds
 * hut: 16 to 240 milliseconds
 * hlt: 2 to 254 milliseconds
*/


/*
Author:	田勇,alias tybitsfox
2020-03-04
 *///}}}

//{{{copy_shadow	将软驱参数拷贝至软驱操作的数据结构中
/*传入参数：无
  作用：将软驱编程必须的参数拷贝至数据结构中便于操作。
  返回值：无
 */
copy_shadow:
	push %ds
	pop %es
	leal fdc_type,%edi
	movl $11,%ecx
	leal bios,%esi
	rep movsb
	ret
//}}}
//{{{wait_for_irq	软驱中断的轮寻函数
/*传入参数：无

  返回值：CF，error if cf is set
 */
wait_for_irq:
	clc
	push %ds
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $0x30,%ecx
1:
	cmpl $1,_flp_flag
	je 2f
	movl $8,%eax
	call delay
	loop 1b
	stc
	movl $3,%eax
	jmp 3f
2:
	movl $0,_flp_flag
3:	
	pop %ds
	ret
//}}}

//{{{init_dma	dma的初始化函数
/*dma编程要点：
  每个MDAC含有两个物理芯片：master(1),slave(0)，每个芯片含有4个频道（channel），16个常规端口，16个扩展端口。软驱默认使用slave,2 channel。
  下面仅介绍(AT机型)和软驱相关的端口：
  slave的常规端口中：0~7称为频道端口，用于指定4个频道所设置的物理内存地址和计数器。每个频道使用2个端口。端口4,5为软驱用，分别设置内存地址和字节数
  					 8~F端口分别为：
					 8：状态寄存器-只读(in)	该端口基本无需使用。
					 	命令寄存器-只写(out) 该端口也基本不用。
					 9：请求寄存器-只写(out) 软驱编程不用。
				 	 10：单频道屏蔽寄存器-只写(out),在对相关频道进行设置时，通过该寄存器屏蔽，解屏蔽指定频道-必用
					 11：模式寄存器-只写(out),指定频道，并对该频道设置传送方式，读写模式。	 -必用
					 12：清指针寄存器-只写(out),由于slave芯片的端口都是8位的，在写16位指令或地址时，需传送2次，每次操作后内部指针指向高位操作，如只需8位输入时，必须使用该寄存器明确的将指针指向低位，写入的数据无要求，只要对该端口进行写操作即可。 -必用
					 13：--- -只读（in） 无用
					 13：重置寄存器-只写(out),对该端口写入任何值都可重置所有4个频道。			-可用
					 14：清除屏蔽寄存器-只写(out)，对该端口写入任意值都可清除所有4个频道的屏蔽。-可用
					 15：写屏蔽寄存器-只写(out),编程无用。
 扩展端口中对应与AT机型的软驱所用的端口为：0x81，为地址页寄存器，也就是20位地址段对应的高4位，因此这里设置数值的单位是64k					 
   
  输入参数：内存缓冲区的20位物理地址，传送的字节数
  传入方式：通过软驱数据结构获取
  该函数仅对dma进行缓冲地址和传送字节数进行初始化，没有对传送方式进行设定
  每次操作的读写传送方式在读写函数中设置

  返回值：无
 */
init_dma:
	cli
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $6,%eax
	outb %al,$0xa		#设置使用频道2,并屏蔽
	jmp .+2
	outb %al,$0xc		#清字节高位
	jmp .+2
	movl fdc_dma_off,%eax	#dma 缓冲区地址
	outb %al,$4			#写地址低8位
	jmp .+2
	movb %ah,%al
	outb %al,$4			#写地址高8位
	jmp .+2
	bswap %eax
	movb %ah,%al
	outb %al,$0x81		#设置页基地址（20位的高4位，1代表64k）
	jmp .+2
	outb %al,$0xc
	jmp .+2
	movw fdc_dma_cnt,%ax
	decw %ax
	outb %al,$5			#写传送字节数的低八位
	jmp .+2
	movb %ah,%al
	outb %al,$5			#写传送字节数的高八位
	jmp .+2
	movl $2,%eax
	outb %al,$0xa		#解除频道2的屏蔽
	jmp .+2
	outb %al,$0xc
	sti
	ret
//}}}	
//{{{dma_read_flp	dma读软驱操作
/*传入参数：无
  写模式寄存器端口，工作模式字：0x56,使用通道2,写模式（对内存而言），自动初始化，
  单字节传输。
  
  返回值：无
 */	
dma_read_flp:
	movl $6,%eax
	outb %al,$0xa
	jmp .+2
	outb %al,$0xc
	jmp .+2
	movl $0x56,%eax
	outb %al,$0xb
	jmp .+2
	outb %al,$0xc
	jmp .+2
	movl $2,%eax
	outb %al,$0xa
	jmp .+2
	outb %al,$0xc
	ret
//}}}
//{{{dma_write_flp	dma写软驱操作
/*传入参数：无
  写模式寄存器端口（0xb）,工作模式字：0x5a,读模式（对内存而言）,其余同read

  返回值：无
 */	
dma_write_flp:
	movl $6,%eax
	outb %al,$0xa
	jmp .+2
	outb %al,$0xc
	jmp .+2
	movl $0x5a,%eax
	outb %al,$0xb
	jmp .+2
	outb %al,$0xc
	jmp .+2
	movl $2,%eax
	outb %al,$0xa
	jmp .+2
	outb %al,$0xc
	ret
//}}}

//{{{motor_on	启动马达
/*参数传递方式：软驱数据结构表

  返回值：无
 */	
motor_on:
	clc
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $0x10,%eax
	movb fdc_drv,%cl
	rolb %cl,%al
	addb %cl,%al
	addb $4,%al			#set controller enable
	cmpb $1,fdc_dma
	jne 1f
	addb $8,%al			#now the command byte may be 0x1c
1:
	movl $FDC_PORT_DOR,%edx
	outb %al,%dx
	movl $50,%eax
	call delay
	ret
//}}}
//{{{motor_off	关闭马达
/*传入参数：无

  返回值：无
 */	
motor_off:
	movl $4,%eax		#only set reset bit
	movl $FDC_PORT_DOR,%edx
	outb %al,%dx
	movl $50,%eax
	call delay
	ret
//}}}	

//{{{cmd_check_int	中断检测命令 0x8
/*传入参数：无
  FDC检测中断命令代码：0x8

  返回值：CF cf=1 error,eax=error code;cf=0 success  
 */
cmd_check_int:
	movl $FDC_CMD_CHECK_INT,%eax
	call fdc_send
	jc 1f
	call fdc_recv
	jc 1f
	xorl %eax,%eax
	jmp 2f
1:
	addl $0x10,%eax
2:
	ret
//}}}	
//{{{cmd_check_status	检查驱动器状态 0x4
/*传入参数取自系统结构表

  返回值：CF，cf=1 error;cf=0 success
 */	
cmd_check_status:
	movb fdc_drv,%bh
	movb fdc_head,%bl
	shlb $2,%bl
	addb %bh,%bl
	andl $0x7,%ebx
	movl $FDC_CMD_CHECK_STAT,%eax
	call fdc_send
	jc 1f
	movl %ebx,%eax
	call fdc_send
	jc 1f
	call fdc_recv
	jc 1f
	xorl %eax,%eax
	jmp 2f
1:
	addl $0x80020000,%eax
2:
	ret
//}}}
//{{{cmd_seek_head	磁头定位，寻道命令 0xf
/*传入参数依据系统结构表
  所需参数：驱动器号，磁头号，柱面号

  返回值：CF cf=1 error;cf=0 success
 */	
cmd_seek_head:
	movb fdc_drv,%bh
	movb fdc_head,%bl
	shlb $2,%bl
	addb %bh,%bl
	andl $7,%ebx
	movl $FDC_CMD_SEEK,%eax
	call fdc_send
	jc 1f
	movl %ebx,%eax
	call fdc_send
	jc 1f
	movb fdc_trk,%al
	call fdc_send
	jc 1f
	call wait_for_irq
	jc 1f
	call cmd_check_int
	jc 1f
	movl $fdc_stat_buff,%esi
	incl %esi					#取得返回的定位，并比较
	lodsb
	cmpb fdc_trk,%al
	je 2f
	stc
	movl $5,%eax
1:
	addl $0x80030000,%eax
2:
	ret
//}}}
//{{{cmd_read_sector	读扇区命令 0x6
/*传入参数依据系统结构表
  所需参数：驱动器号，磁头号，柱面号，扇区号，MT，MFM，SK

  返回值：CF cf=1 error,cf=0 success
 */	
cmd_read_sector:
	call dma_read_flp
	xorl %eax,%eax
	movb $FDC_CMD_READ_SECT,%al
	movb fdc_mt,%ah
	rorb $1,%ah
	addb %ah,%al
	movb fdc_mfm,%ah
	rorb $2,%ah
	addb %ah,%al
	movb fdc_sk,%ah
	rorb $3,%ah
	addb %ah,%al		#create command with MT,MFM,SK
	call fdc_send		#send command
	jc 1f
	movb fdc_head,%al
	rolb $2,%al
	addb fdc_drv,%al	#create para1
	call fdc_send		#send para1
	jc 1f
	movb fdc_trk,%al	#get track number
	call fdc_send		#send para2
	jc 1f
	movb fdc_head,%al	#get head number
	call fdc_send		#send para3
	jc 1f
	movb fdc_bsec,%al	#get begin sector's number
	call fdc_send		#send para4
	jc 1f
	movb fdc_bytes_peer_sect,%al		#get bytes peer sector
	call fdc_send		#send para5
	jc 1f
	movb fdc_sect_peer_track,%al		#get sectors peer track
	call fdc_send		#send para6
	jc 1f
	movb fdc_gap,%al		#get GAP
	call fdc_send		#send para7
	jc 1f
	movb fdc_data_length,%al			#get data length
	call fdc_send		#send para8
	jc 1f
	xorl %eax,%eax
	call wait_for_irq
	jc 1f
	call fdc_recv
	jc 1f
	call cmd_check_int
	jc	1f
	movl $0,%eax
	jmp 2f
1:
	addl $0x80040000,%eax
2:
	ret
//}}}	
//{{{cmd_write_sector	写扇区命令	0x5
/*传入参数：驱动器号，磁头号，柱面号，扇区号，MT，MFM，SK
注意：该命令字中SK无效，即SK必须为0。所以，构造命令字时应自动忽略SK
  返回值：CF cf=1 error,cf=0 success
 */
cmd_write_sector:
	call dma_write_flp
	xorl %eax,%eax
	movb $FDC_CMD_WRITE_SECT,%al
	orb fdc_mfm,%ah
	rorb $1,%ah
	orb fdc_mt,%ah
	rorb $1,%ah
	addb %ah,%al			#create command with MT,MFM,NOT SK
	call fdc_send
	jc 1f
	movb fdc_head,%al
	rolb $2,%al
	addb fdc_drv,%al		#create para1
	call fdc_send
	jc 1f
	movb fdc_trk,%al		#track number para2
	call fdc_send
	jc 1f
	movb fdc_head,%al		#head number para3
	call fdc_send
	jc 1f
	movb fdc_bsec,%al		#begin sector's number para4
	call fdc_send
	jc 1f
	movb fdc_bytes_peer_sect,%al	#get bytes peer sector para5
	call fdc_send
	movb fdc_sect_peer_track,%al	#get sector peer track para6
	call fdc_send
	movb fdc_gap,%al		#GAP para7
	call fdc_send
	jc 1f
	movb fdc_data_length,%al		#get data length para8
	call fdc_send
	jc 1f
	xorl %eax,%eax
	call wait_for_irq
	jc 1f
	call fdc_recv
	jc 1f
	call cmd_check_int
	jc 1f
	movl $0,%eax
	jmp 2f
1:
	addl $0x80040000,%eax
2:	
	ret
//}}}	
//{{{cmd_specify	定义基准参数函数 0x3
/*传入参数：依据系统结构表
  所需参数：srt,hut,hlt

  返回值：CF cf=1 error，cf=0 success
 */
cmd_specify:
	xorl %eax,%eax
	movb $FDC_CMD_SPECIFY,%al
	call fdc_send
	jc 1f
	movb fdc_srt,%al
	rolb $4,%al
	addb fdc_hut,%al
	call fdc_send
	jc 1f
	movb fdc_hlt,%al
	shlb $1,%al
#	incb %al			#dma model	测试证明：non-dma位置位表示不使用DMA！！
	call fdc_send
	jnc 2f
1:
	addl $0x80050000,%eax
2:	
	ret
//}}}
//{{{cmd_calibrate	磁头复校命令 0x7
/*传入参数：依据系统结构表
  所需参数：

  返回值：CF cf=1 error,cf=0 success
 */	
cmd_calibrate:
	pushl %ebp
	movl %esp,%ebp
	movl $10,%ecx
1:	
	pushl %ecx
	movb $FDC_CMD_CALIBRATE,%al
	call fdc_send
	jc 2f
	xorl %eax,%eax
	movb fdc_drv,%al
	call fdc_send
	jc 2f
	call wait_for_irq
	jc 2f
	call cmd_check_int
	jc 2f
	leal fdc_stat_buff,%esi
	incl %esi
	lodsb
	cmpb $0,%al
	je 9f
	popl %ecx
	loop 1b
	stc
2:	
	addl $0x80070000,%eax
9:
	movl %ebp,%esp
	popl %ebp
	ret
//}}}
//{{{cmd_format		磁道格式化命令 0xd
/*传入参数：依据系统结构表
  所需参数：MFM，磁头号，驱动器号，每扇区字节数，每磁道扇区数，GAP，datalength

  返回值：CF cf=1 error,cf=0 success
 */
cmd_format:
	xorl %eax,%eax
	movb fdc_mfm,%ah
	rorb $2,%ah
	movb $FDC_CMD_FORMAT_TRACK,%al
	addb %ah,%al
	call fdc_send				#send command
	jc 1f
	movb fdc_head,%al
	rolb $2,%al
	addb fdc_drv,%al
	call fdc_send				#send para1
	jc 1f
	movb fdc_bytes_peer_sect,%al
	call fdc_send				#send para2
	jc 1f
	movb fdc_sect_peer_track,%al
	call fdc_send				#send para3
	jc 1f
#	movb fdc_gap,%al
	movb fdc_fmt_need_time,%al
	call fdc_send				#send para4
	jc 1f
#	movb fdc_data_length,%al
	movb fdc_fmt_fill,%al
	call fdc_send				#send para5
	jc 1f
	xorl %eax,%eax
	call wait_for_irq
	jc 1f
	call fdc_recv
	jc 1f
	call cmd_check_int
	jnc 2f
1:
	addl $0x80080000,%eax
2:	
	ret
//}}}	
//{{{cmd_read_track	读磁道命令 0x2
/*传入参数：依据系统结构表
  所需参数：MFM，SK，磁头号，驱动器号，磁道号，磁头号，扇区号，扇区大小，
  每磁道扇区数，GAP，数据长度.

  返回值：CF cf=1 error,cf=0 success
 */
cmd_read_track:
	call dma_read_flp
	xorl %eax,%eax
	movb fdc_sk,%ah
	rorb $1,%ah
	orb fdc_mfm,%ah
	rorb $2,%ah
	movb $FDC_CMD_READ_TRACK,%al
	addb %ah,%al
	call fdc_send					#send command
	jc 8f
	movb fdc_head,%al
	rolb $2,%al
	orb fdc_drv,%al
	call fdc_send					#send para1
	jc 8f
	movb fdc_trk,%al
	call fdc_send					#send para2
	jc 8f
	movb fdc_head,%al
	call fdc_send					#send para3
	jc 8f
	movb fdc_bsec,%al
	call fdc_send					#send para4
	jc 8f
	movb fdc_bytes_peer_sect,%al	#send para5
	call fdc_send
	jc 8f
	movb fdc_sect_peer_track,%al	#send para6
	call fdc_send
	jc 8f
	movb fdc_gap,%al
	call fdc_send					#send para7
	jc 8f
	movb fdc_data_length,%al
	call fdc_send					#send para8
	jc 8f
	call wait_for_irq
	jc 8f
	call fdc_recv
	jc 8f
	call cmd_check_int
	jnc 9f
8:
	addl $0x80080000,%eax
9:	
	ret
//}}}	


//{{{fdc_send	原子操作，向FDC发送命令的函数
/*传入参数：待发送的命令或命令相关的参数，该函数每次只发送一条命令或一个参
  数，带有多参数的命令需重复调用该函数依次发送所有的命令和参数。
  参数所用寄存器：ax
  ax=传入的一条命令或一个参数

  返回值：CF，cf=1 error,ax=error code;cf=0 success
 */
fdc_send:
	clc
	pushl %ecx
	pushl %edx
	pushl %eax
	movl $20,%ecx	#20 times 1/100 peer times
1:
	movl $FDC_PORT_MSR,%edx
	inb %dx,%al
	jmp .+2
	jmp .+2
	testb $0x80,%al
	jnz 2f
	movl $5,%eax
	call delay
	loop 1b
	stc
	movl $1,(%esp)
	jmp 3f
2:
	movl (%esp),%eax
	movl $FDC_PORT_FIFO,%edx
	outb %al,%dx
	movl $0,(%esp)
3:
	popl %eax
	popl %edx
	popl %ecx
	ret
//}}}	
//{{{fdc_recv	原子操作，读取FDC返回的执行命令的结果或状态
/*传入参数：无
  读取命令与发送命令函数的一个不同的地方是，读取命令调用一次就读取所有的返
  回结果和状态（最多返回7个结果和状态字节）。为了便于查询这些返回字节，需将
  他们保存在一个缓冲区中。
  返回值：CF，cf=1 error，ax=error code;cf=0 success
 */
fdc_recv:
	clc
	pushal
	leal fdc_stat_buff,%esi
	movl $0,%ebx
	movl $0,%eax
	movl $20,%ecx
1:
	movl $FDC_PORT_MSR,%edx
	inb %dx,%al
	jmp .+2
	jmp .+2
	testb $0x10,%al
	jnz 2f
	movl $5,%eax
	call delay
	loop 1b
	jmp 3f
2:
	movl $FDC_PORT_FIFO,%edx
	inb %dx,%al
	jmp .+2
	jmp .+2
	movb %al,(%ebx,%esi)
	incl %ebx
	movl $20,%ecx
	cmpl $8,%ebx
	jb 1b
	stc
	movl $2,%eax		#basically it couldn't be run to here
3:	
	popal
	ret
//}}}

//{{{init_fdc_struct	初始化系统数据结构
/*传入参数：暂无，目前该结构仅面对标准3.5英寸/1.44M，软驱A进行初始化，若对其他
  标准支持，则在此加入初始化参数。
  so~,对上述标准的软驱，这些设置是固定的：
  MT=0,MFM=1,SK=1,fdc_drv=0,heads=2,byte peer sector=512B,sector peer track=18,
  max track=80
  total size=512*18*80*2=1474560Byte = 1.44M
  返回值：无
 */
init_fdc_struct:
	movl $KS_DS,%eax
	movw %ax,%ds
	movl $fdc_type,%esi
	lodsw
	cmpw $0,%ax
	jnz 1f
	call copy_shadow
1:
	movb $0,fdc_mt				#MT=0
	movb $1,fdc_mfm				#MFM=1
	movb $1,fdc_sk				#SK=1
	movb $0,fdc_drv				#driver:A
	movb $0,fdc_head			#current head
	movb $1,fdc_dma				#use dma
	movb $0,fdc_trk				#track number, 0-base
	movb $7,fdc_bsec			#sector which to begin read/write 1-base
	movb $4,fdc_csec			#numbers of sector which to be read/write
	movb $0,fdc_cmd				#next command will be run
	movl $DMA_OFF,fdc_dma_off	#dma buffer address
	movw $DMA_LEN,fdc_dma_cnt	#size of dma buffer
	ret
//}}}	
//{{{dispatch_fdc_cmd	FDC命令执行函数
/*传入参数：无，该函数仍是依据fdc_struct的设置来执行不同的fdc命令
  再调用该函数之前，请务必更新fdc_cmd，例如：
  movb $FDC_CMD_READ_TRACK,fdc_cmd
  call dispatch_fdc_cmd

  返回值：该函数返回的是各具体命令的返回值。CF，cf=1 error，eax=err code
  另：标号：.L1,.L12是硬编码的，不玩它了 ;）
 */	
dispatch_fdc_cmd:
	cmpb $FDC_CMD_READ_TRACK,fdc_cmd
	jne 1f
	//here will run command 2
/*	call motor_on				2,22,42,62 all invalid command?? no use then
	call cmd_check_status
	jc 9f
	call cmd_seek_head
	jc 9f
	call cmd_read_track
	jc 9f
	call motor_off
	clc  */
	movl $0,%eax
	ret
1:
	cmpb $FDC_CMD_SPECIFY,fdc_cmd
	jne 2f
	call cmd_specify
	ret
2:
	cmpb $FDC_CMD_CHECK_STAT,fdc_cmd
	jne 3f
	call motor_on
	call cmd_check_status
	jc 9f
	call motor_off
	xorl %eax,%eax
	clc
	ret
3:
	cmpb $FDC_CMD_WRITE_SECT,fdc_cmd
	jne 4f
	call motor_on
	call cmd_check_status
	jc 9f
	call cmd_seek_head
	jc 9f
	call cmd_write_sector
	jc 9f
	call motor_off
	clc
	movl $0,%eax
	ret
4:
	cmpb $FDC_CMD_READ_SECT,fdc_cmd
	jne 5f
	call motor_on
	call cmd_check_status
	jc 9f
	call cmd_seek_head
	jc 9f
	call cmd_read_sector
	jc 9f
	call motor_off
	clc
	movl $0,%eax
	ret
5:
	cmpb $FDC_CMD_CALIBRATE,fdc_cmd
	jne 6f
	call motor_on
	call cmd_calibrate
	jc 9f
	call motor_off
	clc
	ret
6:
	cmpb $FDC_CMD_CHECK_INT,fdc_cmd
	jne 7f
	call motor_on
	call cmd_check_int
	jc 9f
7:
	cmpb $FDC_CMD_WRITE_DEL_S,fdc_cmd
	jne 8f
	movl $9,%eax
	jmp .
8:
	cmpb $FDC_CMD_READ_ID_S,fdc_cmd
	jne 1f
	movl $0xa,%eax
	jmp .
1:
	cmpb $FDC_CMD_READ_DEL_S,fdc_cmd
	jne 2f
	movl $0xc,%eax
	jmp .
2:
	cmpb $FDC_CMD_FORMAT_TRACK,fdc_cmd
	jne 3f
	call motor_on
	call cmd_check_status
	jc 9f
	call cmd_seek_head
	jc 9f
	call cmd_format
	jc 9f
	call motor_off
	ret
3:	
	cmpb $FDC_CMD_SEEK,fdc_cmd
	jne 4f
	call motor_on
	call cmd_check_status
	jc 9f
	call cmd_seek_head
	jc 9f
	call motor_off
	mov $0,%eax
	clc
	ret
4:
	movl $0xfffaaaa,%eax
	jmp .
9:
	ret
//}}}







