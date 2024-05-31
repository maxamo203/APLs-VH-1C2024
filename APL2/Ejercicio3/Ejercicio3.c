#include <stdlib.h>
#include <stdio.h>
#include "../Bibliotecas/headers/parsearParametros.h"
#include <unistd.h>
#include <wait.h>
#include <signal.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <time.h>
#include <errno.h>


#define NOMBRE_FIFO "fifo1"
#define BUFFER_SIZE 512
#define MIN_MED 30
#define MAX_MED 200
//volatile sig_atomic_t terminar = 0; //volatile es para indicar al compilador que la variable puede cambiar en cualquier momento de la 
//ejecucion del programa y no haga optimizaciones sobre ella, y sig_atomic_t es un tipo de dato donde la lectura y escritura son atomicas
typedef struct{
    int numero;
    int medicion;
} Lectura;
void mostrarAyuda(){
    puts("Mostrando ayuda muy desarrollada");
    puts("-l/--log");
    puts("-n/--numero");
    puts("-s/--segundos");
    puts("-m/--mensajes");
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
void manejarCierre(){
    printf("Señal detectada\n");
    //terminar = 1;
    //errno = EINTR;
}
int parsearLectura(char *buff, Lectura *lec){ //el sensor escribe en formato numero:medicion
    int posSeparador = -1;
    char numero[64] = {0};
    char medicion[64] = {0};
    int i = 0;
    while (*buff != 0){
        if (*buff == ':'){
            posSeparador = 1;
            i = 0;
            buff++;
        }
        if(posSeparador == -1){ //antes del :
            numero[i++] = *buff;
        }else{
            medicion[i++] = *buff;
        }

        buff++;
    }
    if(posSeparador == -1){
        printf("Error parseando\n");
        return 0;
    }
    lec->numero = atoi(numero);
    lec->medicion = atoi(medicion);
    return 1;
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
int monitor(char* log) {
    // if(signal(SIGTERM, manejarCierre) == SIG_ERR) {
    //     perror("No se pudo establecer el manejador de señal");
    //     return 1;
    // }
    puts("Soy yo, el monitor");
    struct sigaction sa;
    sa.sa_handler = manejarCierre;
    sa.sa_flags = 0; // Ensure the signal interrupts the open call
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIGTERM, &sa, NULL) == -1) {
        perror("Error al establecer el manejador de señal");
        exit(EXIT_FAILURE);
    }

    time_t t = time(NULL);
    struct tm tiempoActual;
    char* formato = "%d-%m-%Y %H:%M:%S";
    char fechaHora[70];
    if(access(NOMBRE_FIFO, F_OK) == -1) { 
        mkfifo(NOMBRE_FIFO, 0666); 
    }

    char buffer[BUFFER_SIZE];
    //int fifo = open(NOMBRE_FIFO, O_RDONLY);
    int fifo; 
    if ((fifo = open(NOMBRE_FIFO, O_RDONLY)) == -1) {
        printf("%d\n", errno);
        perror("Error al abrir FIFO");
        unlink(NOMBRE_FIFO);
        return 1;
    }
    Lectura lectura;
    while (1) {
        //printf("%d\n", errno);
        ssize_t bytes_read = read(fifo, buffer, BUFFER_SIZE);
        
        if(errno == EINTR){
            puts("ERRORMORTAL");
            break;
        }
        else if (bytes_read > 0){
            FILE* logfile = fopen(log, "a");
            tiempoActual = *localtime(&t);
            strftime(fechaHora, sizeof fechaHora, formato, &tiempoActual);
            parsearLectura(buffer, &lectura); //TODO revisar que pasa cuando hay mas de un mensaje encolado (lo toma como uno solo)
            printf("\n%s--SENSOR n° %d, MEDICION: %d ----Original: %s\n", fechaHora, lectura.numero, lectura.medicion, buffer);
            fprintf(logfile, "%s--SENSOR n° %d, MEDICION: %d\n", fechaHora, lectura.numero, lectura.medicion);
            fclose(logfile);
        }else if(bytes_read == 0){
            usleep(1000000);
        }
    }
    puts("CERRANDO BIEN");
    close(fifo);
    unlink(NOMBRE_FIFO);
    return 0;
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
int sensor(int numero, float segundos, int cantMensajes){
    int enviados = 0;
    int fifo = open(NOMBRE_FIFO, O_WRONLY);
    if(fifo == -1){ //puede no existir el fifo, el monitor borra el fifo cuando termina
        puts("No se pudo abrir el fifo, saliendo");
        return -1;
    }
    char buffer[BUFFER_SIZE];
    long int tiempo = segundos * 1000000;
    srand(getpid());
    while(enviados < cantMensajes){
        int random = (rand() % (MAX_MED-MIN_MED + 1)) + MIN_MED;
        printf("\nMando -> %d:%d", numero, random);
        sprintf(buffer, "%d:%d", numero, random);
        write(fifo,buffer, BUFFER_SIZE);
        enviados++;
        usleep(tiempo);
    }
    close(fifo);
}
int main(int argc, char* argv[]){
    char *log = NULL,*numero = NULL, *segundos = NULL, *mensajes = NULL, *help = NULL;
    char * opcionesLargas[] = {"log","numero", "segundos","mensajes", "help"};
    char ** variables [] = {&log, &numero, &segundos, &mensajes,&help};
    parsearParametros(argv, argc, "l:n:s:m:h", opcionesLargas, 2, variables);
    //printf("%s es el directorio y %s la ayuda %s\n", log, numero, argv[0]);
    if (argc == 1 || help != NULL){ // el nombre del programa tambien cuenta como parametro y esta siempre
        mostrarAyuda();
        freeParametros(5,variables);
        return 0;
    }
    if(log != NULL){ //si le paso un log es un monitor, sino, es un sensor
        if(existeMonitor(argv[0])){
            puts("Ya existe un proceso monitor");
        }
        else{
            int pid = fork();
            if(pid == 0){
                monitor(log);
            }else{
                puts("Se inicio un proceso monitor");
            }
        }
        puts("saliendo dou");
        freeParametros(5, variables);
        exit(0);
    }
    //los procesos (el que inicia y el demonio) no van a llegar a esta parte del codigo por el exit
    //entonces a partir e aca es codigo que van a ejecutar los sensores
    if(validarParametrosSensor(numero, segundos, mensajes) != 0){ // si parametros invalidos
        return 1;
    }
    int pid = fork();   //genero al sensor tambien como demonio
    if(pid == 0){
        sensor(atoi(numero), atof(segundos), atoi(mensajes));
    }
    printf("\nTermine de meterle 1\n");
    freeParametros(5, variables);
    return 0;
}