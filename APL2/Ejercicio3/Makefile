all: monitor sensor clean

monitor: monitor.o parsearParametros.o
	gcc monitor.o parsearParametros.o -o Monitor

sensor: sensor.o parsearParametros.o
	gcc sensor.o parsearParametros.o -o Sensor

monitor.o: ./codigo/monitor.c
	gcc -c ./codigo/monitor.c

sensor.o: ./codigo/sensor.c
	gcc -c ./codigo/sensor.c

parsearParametros.o: ./codigo/parsearParametros/parsearParametros.c
	gcc -c ./codigo/parsearParametros/parsearParametros.c

clean:
	rm -f *.o
