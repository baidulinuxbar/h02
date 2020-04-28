#.EXPORT_ALL_VARIABLES:
ifeq ($(MAKELEVEL),0)
TOPDIR	:=	$(shell pwd)
export HDIR	:=	$(TOPDIR)/include
DIRS	:=	boot head kernel
CLEAN	:=	make clean
all:doit
else
all:msg
endif

doit:
	@for i in $(DIRS); do \
		$(MAKE) -C $$i; \
	done	
msg:
	@echo "can't running make in this directory"

.PHONY: clean install

install:
	dd bs=512 if=boot/boot.elf of=hdc.img count=2
	dd bs=512 if=head/head.elf of=hdc.img seek=2 count=61
	dd bs=512 if=kernel/kernel.elf of=hdc.img seek=63 count=63
	dd bs=512 if=/dev/zero of=hdc.img seek=126 count=20034
	cp hdc.img ~/

clean:
	@for i in $(DIRS); do \
		$(CLEAN) -C $$i; \
	done
	-rm *.img
