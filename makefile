TOOLCHAIN = aarch64-linux-gnu
ASFLAGS   = -Wall -O2 -ffreestanding -nostdinc -nostdlib -nostartfiles
LDFLAGS   = -nostdlib -nostartfiles -T link.ld
EMULATOR  = ./qemu-system-aarch64
BOARD     = raspi3

kernel8.img: kernel.o
	$(TOOLCHAIN)-ld $(LDFLAGS) -o kernel8.img kernel.o

kernel.o: kernel.s
	$(TOOLCHAIN)-gcc $(ASFLAGS) -c kernel.s

run: kernel8.img
	$(EMULATOR) -M $(BOARD) -kernel kernel8.img -serial null -serial stdio -display none
