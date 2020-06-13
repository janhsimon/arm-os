TOOLCHAIN = aarch64-linux-gnu
ASFLAGS   = -Wall -O2 -ffreestanding -nostdinc -nostdlib -nostartfiles
LDFLAGS   = -nostdlib -nostartfiles -T link.ld
EMULATOR  = ./qemu-system-aarch64
BOARD     = raspi3

OBJECTS = kernel.o uart.o util.o

kernel8.img: $(OBJECTS)
	$(TOOLCHAIN)-ld $(LDFLAGS) -o kernel8.img $(OBJECTS)

%.o: %.s
	$(TOOLCHAIN)-gcc $(ASFLAGS) -c $<

run: kernel8.img
	$(EMULATOR) -M $(BOARD) -kernel kernel8.img -serial null -serial stdio -display none
