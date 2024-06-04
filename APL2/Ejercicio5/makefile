all: todo

todo: EJ5_cliente.o EJ5_servidor.o tablero.o parsearParametros.o
	gcc EJ5_cliente.o tablero.o parsearParametros.o -o EJ5_cliente
	gcc EJ5_servidor.o tablero.o parsearParametros.o -o EJ5_servidor

EJ5_cliente.o: EJ5_cliente.c
	gcc -c EJ5_cliente.c
EJ5_servidor.o: EJ5_servidor.c
	gcc -c -lpthread EJ5_servidor.c
tablero.o: ../Bibliotecas/core/tablero.c
	gcc -c ../Bibliotecas/core/tablero.c
parsearParametros.o: ../Bibliotecas/core/parsearParametros.c
	gcc -c ../Bibliotecas/core/parsearParametros.c
clean:
	rm -f *.o
cleanall:
	rm -f *.o EJ5_cliente EJ5_servidor