all: ejecutable clean

ejecutable: Ejercicio2.o
	gcc -o Ejecutable Ejercicio2.o

Ejercicio1.o: Ejercicio2.c
	gcc -c Ejercicio2.c

clean:
	rm -f *.o
