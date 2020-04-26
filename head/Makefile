TMP_FILE	:=	$(wildcard *.s)
SRC_FILE	:=	$(notdir $(TMP_FILE))
OBJ_FILE	:=	$(SRC_FILE:.s=.o)
BIN_FILE	:=	$(OBJ_FILE:.o=.bin)
ELF_FILE	:=	$(BIN_FILE:.bin=.elf)
CMD_OBJCOPY	:=	objcopy -R .pdr -R .comment -R .note -S -O binary

all:$(ELF_FILE)

%.elf:%.bin
	$(CMD_OBJCOPY) $< $@
%.bin:%.o
	ld -o $@ $< -Ttext 8000
%.o:%.s
	as -o $@ $< -I$(HDIR)
.PHONY:	clean
clean:
	rm *.elf

