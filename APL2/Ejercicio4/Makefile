all: servidor cliente

servidor: servidor.o
	cc -o servidor servidor.o

servidor.o: servidor.c
	cc -c servidor.c

cliente: cliente.o
	cc -o cliente cliente.o

cliente.o: cliente.c
	cc -c cliente.c