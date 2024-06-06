#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <wait.h>
#include <string.h>
#include <sys/prctl.h>
#include <signal.h>

void procesarParametros(int,char**);
void mostrarAyuda();

void mostrar(char*);
void cambiarNombre(char*);
void matar_hijos(pid_t);
pid_t padre();
void hijo1();
void hijo3();
void zombie();
void demonio();
void nieto1();
void nieto2();
void nieto3();
void biznieto();



int main(int argc, char *argv[]){
	pid_t grupoProcesos;
	procesarParametros(argc,argv);
	grupoProcesos = padre();
	getchar();
	matar_hijos(grupoProcesos);
	return 0;
}

void matar_hijos(pid_t pid_padre) {
    pid_t pgid = getpgid(pid_padre);
    kill(-pgid, SIGKILL);
}

pid_t padre(){
	pid_t pid;
	cambiarNombre("Padre");
	mostrar("Padre");
	pid = fork();

	if(pid == 0)
		hijo1();
	else{
		pid = fork();
		if(pid == 0)
			zombie();
		else{
			pid = fork();
			if(pid == 0){
				hijo3();
			}
			waitpid(pid,NULL,WUNTRACED);
		}
	}
	return getpid();
}

void hijo1(){
	pid_t pid;

	cambiarNombre("Hijo 1");
	mostrar("Hijo 1");

	pid = fork();
	if(pid == 0)
		nieto1();
	else{
		pid = fork();
		if(pid == 0)
			nieto2();
		else{
			pid = fork();
			if(pid == 0)
				nieto3();
		}
	}
}

void nieto1(){
	cambiarNombre("Nieto 1");
	mostrar("Nieto 1");
}

void nieto2(){
	cambiarNombre("Nieto 2");
	mostrar("Nieto 2");
}

void nieto3(){
	pid_t pid;
	cambiarNombre("Nieto 3");
	mostrar("Nieto 3");
	pid = fork();
	if(pid == 0)
		biznieto();
}

void biznieto(){
	cambiarNombre("Biznieto");
	mostrar("Biznieto");
}

void zombie(){
	cambiarNombre("Zombie");
	mostrar("Zombie");
	exit(1);
}

void hijo3(){
	pid_t pid;
	cambiarNombre("Hijo 3");
	mostrar("Hijo 3");

	pid = fork();
	if(pid == 0){
		demonio();
	}
	exit(0);
}

void demonio(){
	cambiarNombre("Demonio");
	mostrar("Demonio");
	while(1);
}

void cambiarNombre(char* nombre){
	prctl(PR_SET_NAME,nombre,0,0,0);
}

void mostrar(char* nombre){
	printf("Soy el proceso %s con PID %04d, mi padre es %04d\n", nombre, getpid(), getppid());
}

void procesarParametros(int argc,char *argv[]){
	if(argc > 2){
		printf("Parámetros inválidos\n");
		exit(1);
	}
	if(argc > 1){
		if((strcmp(argv[1],"-h") == 0) || (strcmp(argv[1],"--help") == 0))
			mostrarAyuda();
		else{
			printf("Parametro invalido\n");
			exit(1);
		}
	}
}

void mostrarAyuda(){
	printf("Este programa crea la jerarquia de procesos pedida en la consigna. No recibe parametros\n");
	exit(0);
}
