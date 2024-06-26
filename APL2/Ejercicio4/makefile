all: todo

todo: EJ4_cliente.o EJ4_servidor.o tablero.o semaforos.o
	gcc EJ4_cliente.o tablero.o semaforos.o -o EJ4_cliente
	gcc EJ4_servidor.o tablero.o semaforos.o -o EJ4_servidor

EJ4_cliente.o: EJ4_cliente.c
	gcc -c EJ4_cliente.c
EJ4_servidor.o: EJ4_servidor.c
	gcc -c EJ4_servidor.c
tablero.o: ../Bibliotecas/core/tablero.c
	gcc -c ../Bibliotecas/core/tablero.c
semaforos.o: semaforos.c
	gcc -c semaforos.c

clean:
	rm -f *.o
cleanall:
	rm -f *.o EJ4_cliente EJ4_servidor