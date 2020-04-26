.EXPORT_ALL_VARIABLES:
ifeq ($(MAKELEVEL),0)
TOPDIR	:=	$(shell pwd)
HDIR	:=	$(TOPDIR)/include
DIRS	:=	boot head
all:doit
else
all:msg
endif

doit:
	$(foreach dir,$(DIRS),$(cd dir;make))
msg:
	@echo "can't running make in this directory"
.PHONY clean install
install:
	dd bs=512 if=boot/boot.elf of=hdc.img count=2
	dd bs=512 if=head/head.elf of=hdc.img seek=2 count=61
	dd bs=512 if=/dev/zero of=hdc.img seek=63 count=20097
clean:
	$(foreach dir,$(DIRS),$(cd dir;make clean))
	rm *.img
