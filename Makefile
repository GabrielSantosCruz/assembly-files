mostrador.o: mostrador.s
	as -o mostrador.o mostrador.s

mostrador: mostrador.o
	ld -o mostrador mostrador.o

run: mostrador
	./mostrador
