TMP_FILE	:=	$(wildcard *.s)
SRC_FILE	:=	$(notdir $(TMP_FILE))
ELF_FILE	:=	$(SRC_FILE:.s=.elf)
CMD_OBJCOPY	:=	objcopy -R .pdr -R .comment -R .note -S -O binary

all:$(ELF_FILE)

%.elf:%.bin
	$(CMD_OBJCOPY) $< $@
%.bin:%.o
	ld -o $@ $< -Ttext 200000
%.o:%.s
	as -o $@ $< -I$(HDIR)
.PHONY: clean
clean:
	rm *.elf
