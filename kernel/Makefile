TMP_FILE	:=	$(notdir $(wildcard *.s))
TMPS_FILE	:=	$(notdir $(wildcard fint/*.S))
TMPC_FILE	:=	$(notdir $(wildcard *.c))
SRC_FILE	:=	$(TMP_FILE:.s=.o)
SRS_FILE	:=	$(TMPS_FILE:.S=.o)
SRCC_FILE	:=	$(TMPC_FILE:.c=.o)
OBJ_FILE	:=	$(SRC_FILE) $(SRS_FILE) $(SRCC_FILE)
ELF_FILE	:=	$(SRC_FILE:.o=.elf)
CMD_OBJCOPY	:=	objcopy -R .pdr -R .comment -R .note -R .eh_frame -S -O binary
CFLAGS		:=	-fno-builtin -nostdinc -fno-pic -c -o
INTPATH		:=	fint/

all:$(ELF_FILE)

%.elf:%.bin
	$(CMD_OBJCOPY) $< $@
%.bin:$(OBJ_FILE)
	ld -o $@ $^ -Ttext 200000
%.o:%.s
	as -o $@ $< -I$(HDIR)
%.o:$(INTPATH)%.S
	gcc -traditional -c -o $@ $< -I$(HDIR)
%.o:%.c
	gcc $(CFLAGS) $@ $< -I$(HDIR)
.PHONY: clean
clean:
	rm *.elf
