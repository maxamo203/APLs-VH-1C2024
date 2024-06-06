#include <stdlib.h>
#include <stdio.h>
#include "./parsearParametros/parsearParametros.h"
#include <unistd.h>
#include <wait.h>
#include <signal.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <time.h>
#include <errno.h>

#define NOMBRE_FIFO "/tmp/fifoLecturas"
#define TAM_BUFFER 512
#define MIN_MED 30
#define MAX_MED 200

void mostrarAyuda();
int validarParametrosSensor(char*,char*,char*);
int sensor(int,float,int);
int isNumber(const char*);

int main(int argc, char* argv[]){
	char *numero = NULL, *segundos = NULL, *mensajes = NULL, *help = NULL;
	char * opcionesLargas[] = {"numero", "segundos","mensajes", "help"};
    	char ** variables [] = {&numero, &segundos, &mensajes,&help};

	parsearParametros(argv, argc, "n:s:m:h", opcionesLargas, 4, variables);
	if (help != NULL){
        	mostrarAyuda();
        	freeParametros(4,variables);
        	return 0;
    	}
	if(validarParametrosSensor(numero, segundos, mensajes) != 0){
        	printf("ERROR: Parametros invalidos\n");
		return 1;
    	}

	int pid = fork();
    	if(pid == 0){
        	sensor(atoi(numero), atof(segundos), atoi(mensajes));
    	}

    	freeParametros(4, variables);
	return 0;
}

void mostrarAyuda(){
	printf("Parametros:");
	printf("-n/--numero: Numero del sensor");
	printf("-s/--segundos: Intervalo de segundos para el envio del mensaje");
	printf("-m/--mensajes: Cantidad de mensajes a enviar");
}


int validarParametrosSensor(char *numero,char *segundos, char *mensajes){
    	if(numero == NULL || segundos == NULL || mensajes == NULL){
        	printf("Al querer iniciar un sensor, algunos parametros no fueron pasados, indiquelos con -n -s -m\n");
        	return 1;
    	}
    	if(!isNumber(numero) || !isNumber(segundos) || !isNumber(mensajes)){
        	puts("Todos los parametros deben ser numericos");
        	return 2;
    	}
    	if(atof(segundos) <= 0 || atoi(mensajes)<1){
        	puts("El intervalo de tiempo y la cantidad de mensajes deben ser mayores a 0");
        	return 3;
    	}
    	return 0;
}

int isNumber(const char *str) {
 	while (*str) {
        	if (!isdigit(*str) && *str != '.' && *str != ',') {
            		return 0; // No es un número
        	}
        str++;
    	}
    	return 1; // Es un número
}


int sensor(int numero, float segundos, int cantMensajes){
    	int enviados = 0;
    	int fifo = open(NOMBRE_FIFO, O_WRONLY);
    	if(fifo == -1){ //puede no existir el fifo, el monitor borra el fifo cuando termina
        	puts("No se pudo abrir el fifo, saliendo");
        	return -1;
    	}
    	char buffer[TAM_BUFFER];
    	long int tiempo = segundos * 1000000;
    	srand(getpid());
    	while(enviados < cantMensajes){
        	int random = (rand() % (MAX_MED-MIN_MED + 1)) + MIN_MED;
		sprintf(buffer, "|%d:%d|", numero, random);
        	write(fifo,buffer, TAM_BUFFER);
        	enviados++;
        	usleep(tiempo);
    	}
    	close(fifo);
}


