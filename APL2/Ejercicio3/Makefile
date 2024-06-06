all: monitor sensor clean

monitor: monitor.o parsearParametros.o
	gcc monitor.o parsearParametros.o -o Monitor

sensor: sensor.o parsearParametros.o
	gcc sensor.o parsearParametros.o -o Sensor

monitor.o: ./monitor.c
	gcc -c ./monitor.c

sensor.o: ./sensor.c
	gcc -c ./sensor.c

parsearParametros.o: ../Bibliotecas/core/parsearParametros.c
	gcc -c ../Bibliotecas/core/parsearParametros.c

clean:
	rm -f *.o
cleanall:
	rm -f *.o Monitor Sensor