#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <wait.h>
#include <signal.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include "./parsearParametros/parsearParametros.h"

#define TAM_BUFFER 512
#define FIFO_FILE "/tmp/fifoLecturas"


typedef struct{
    	int numero;
    	int medicion;
}Lectura;

void mostrarAyuda();
int existeMonitor(char*);
int monitor(char*);
void finalizarMonitor();
void parsearLectura(char*,Lectura*);


int main(int argc, char* argv[])
{
	pid_t pid;

	char *log = NULL, *help = NULL;
    	char * opcionesLargas[] = {"log","help"};
    	char ** variables [] = {&log, &help};

    	parsearParametros(argv, argc, "l:h", opcionesLargas, 2, variables);

	if(help != NULL){
		mostrarAyuda();
		freeParametros(2,variables);
		return 0;
	}
	if(log == NULL){
		printf("ERROR: No se especifica archivo de logs\n");
		exit(1);
	}
	if(existeMonitor("Monitor")){
		printf("Ya existe un proceso monitor. Saliendo...\n");
		exit(0);
	}
	pid = fork();
	if(pid == 0){
		monitor(log);
	}
	else{
		printf("Se inicio el proceso monitor\n");
		exit(0);
	}
	freeParametros(2,variables);
	return 0;
}

void finalizarMonitor(int fifo) {
	unlink(FIFO_FILE);
	exit(0);
}

int existeMonitor(char* nombre){
    	FILE* fp;
    	char proc[100];
    	char comando[100];
    	int existeOtro = 0;
    	sprintf(comando, "ps -eo  args | grep %s | grep -v 'grep' | grep '\\-l' -c ", nombre); //-c para que me diga la cantidad de coincidneicas
    	fp = popen(comando, "r"); // busco procesos que tengan el nombre ejercicio3 y tengan el parametro -l
    	if(fp == NULL){
        	printf("Error comprobando si existe otro monitor\n");
        	return 1;
    	}
    	while(fgets(proc, sizeof(proc), fp) != NULL){
        	if(atoi(proc)>1){
            		existeOtro = 1;
        	}
    	}
    	pclose(fp);
    	return existeOtro;
}

int monitor(char* logFile) {
	int archFifo;
	char buffer[TAM_BUFFER];
	FILE* archLog;
	time_t t;
	struct tm tiempoActual;
	char* formato = "%d-%m-%Y %H:%M:%S";
    	char fechaHora[70];
	Lectura lectura;
	int leidos;
	struct sigaction sa;

	memset(&sa,0,sizeof(sa));
	sa.sa_handler = finalizarMonitor;
	if (sigaction(SIGTERM, &sa, NULL) == -1) {
        	perror("sigaction");
        	exit(EXIT_FAILURE);
    	}

	mkfifo(FIFO_FILE,0666);

	archFifo = open(FIFO_FILE,O_RDONLY);

	while(1){
		if((leidos = read(archFifo,buffer,TAM_BUFFER-1)) > 0){
			buffer[leidos] = '\0';
			archLog = fopen(logFile,"a");
			t = time(NULL);
			tiempoActual = *localtime(&t);
			strftime(fechaHora,sizeof(fechaHora),formato,&tiempoActual);
			while(*buffer != '\0'){
				parsearLectura(buffer,&lectura);
				fprintf(archLog,"%s--SENSOR n°: %d, MEDICION: %d\n", fechaHora, lectura.numero, lectura.medicion);
			}
			fclose(archLog);
		}
	}
	return 0;
}

void parsearLectura(char* buffer,Lectura* lectura){ 	//El sensor escribe en formato |numero:medicion|
	char* finalCad;
	char* inicioLectura;

	finalCad = strrchr(buffer,'|');
	*finalCad = '\0';
	inicioLectura = strrchr(buffer,'|');
	sscanf(inicioLectura+1 , "%d:%d" , &lectura->numero , &lectura->medicion);
	*inicioLectura = '\0';
}

void mostrarAyuda(){
    	printf("AYUDA:\n");
    	printf("-l/--log \t Indica el nombre del archivo donde se guardaran las lecturas\n");
	printf("-h/--help \t muestra la ayuda\n");
}
