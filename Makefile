mostrador.o: mostrador.s
	as -o mostrador.o mostrador.s

mostrador: mostrador.o
	ld -o mostrador mostrador.o

vga.o: vga-gpu.s
	as -o vga.o vga-gpu.s

vga: vga.o
	ld -o vga vga.o

run: mostrador
	./mostrador
	./vga
