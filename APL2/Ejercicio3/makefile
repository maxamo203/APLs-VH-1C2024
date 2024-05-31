all: saludo

saludo: Ejercicio3.o parsearParametros.o
	gcc Ejercicio3.o parsearParametros.o -o Ejercicio3

Ejercicio3.o: Ejercicio3.c
	gcc -c Ejercicio3.c
parsearParametros.o: ../Bibliotecas/core/parsearParametros.c
	gcc -c ../Bibliotecas/core/parsearParametros.c

clean:
	rm -f *.o
cleanall:
	rm -f *.o Ejercicio3
