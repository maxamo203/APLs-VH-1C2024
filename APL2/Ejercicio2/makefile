all: comp

comp: Ejercicio2.o parsearParametros.o
	gcc Ejercicio2.o parsearParametros.o -o Ejercicio2 -lm

Ejercicio2.o: Ejercicio2.c
	gcc -c Ejercicio2.c
parsearParametros.o: ../Bibliotecas/core/parsearParametros.c
	gcc -c ../Bibliotecas/core/parsearParametros.c

clean:
	rm -f *.o
cleanall:
	rm -f *.o Ejercicio2