#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <semaphore.h>
#include <signal.h>
#include <time.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h> 


#define MIN_RAND 65
#define MAX_RAND 90
#define COLUMNAS 4
#define FILAS 4
#define PORT 5000
#define SHM_INT 112233
#define SHM_PATH "/bin/ls"
#define SEM_NAME_SV "/memotest_sem_servidor"
#define SEM_NAME_CLIENTE "/memotest_sem_cliente"
#define SEM_NAME_PARTIDA "/memotest_sem_partida"


struct DataRecibida{
    int fila, columna;
};

struct MemoriaCompartida {
    char tableroJugador[FILAS][COLUMNAS];
    int cantMovExitosos;
    int partidaEnProgreso;
    struct DataRecibida movimiento;    
};

struct MemoriaCompartida *memoria;
int shmIdentificador;
sem_t *sem_sv;
sem_t *sem_cliente;
sem_t *sem_partida;
struct MemoriaCompartida *memoria;
//Se utiliza para saber si esta esperando un semaforo cuando recibe la señal SIGUSR1
//Solo util en este caso que solo se espera un tipo de semaforo, de lo contrario se deberia
//tener una variable por semaforo para saber que semaforo se estaba esperando. (O buscar otra solucion).
int esperandoSem = 0;  

int buscarEnCadena(char *cadena, char caracter, int tam) {
    int i = 0;
    while (i < tam && *cadena != caracter) {
        cadena++;
        i++;
    }
    return *cadena == caracter ? 1 : 0;
}

void crearTablero(char tablero[][4]) {
    char caracteres[8];
    int cantPorCaracter[8] = {2, 2, 2, 2, 2, 2, 2, 2};
    srand(time(NULL));

    for (int i = 0; i < 8; i++) {
        int caracter = rand() % (MAX_RAND - MIN_RAND + 1) + MIN_RAND;
        while (buscarEnCadena(caracteres, caracter, sizeof(caracteres) / sizeof(char))) {
            caracter = rand() % (MAX_RAND - MIN_RAND + 1) + MIN_RAND;
        }
        caracteres[i] = caracter;
    }

    for (int i = 0; i < FILAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            int pos = rand() % 8;
            while (cantPorCaracter[pos] == 0) {
                pos = rand() % 8;
            }
            tablero[i][j] = caracteres[pos];
            cantPorCaracter[pos]--;
        }
    }
}

void inicializarTablero(char tablero[][COLUMNAS]) {
    for (int i = 0; i < COLUMNAS; i++)
        for (int j = 0; j < COLUMNAS; j++)
            tablero[i][j] = '-';
}

int revelarLetra(char tableroPartida[][COLUMNAS], char tableroJugador[][COLUMNAS], struct DataRecibida *movimiento) {
    if (tableroJugador[movimiento->fila][movimiento->columna] != '-') {
        return 0;
    }

    tableroJugador[movimiento->fila][movimiento->columna] = tableroPartida[movimiento->fila][movimiento->columna];
    return 1;
}

void mostrarTablero(char tablero[][COLUMNAS]) {
    for (int i = 0; i < COLUMNAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            printf("%c ", tablero[i][j]);
        }
        printf("\n");
    }
    puts(" ");
}

void ocultarLetra(char tablero[][COLUMNAS], char letra) {
    for (int i = 0; i < COLUMNAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            if (tablero[i][j] == letra) {
                tablero[i][j] = '-';
                puts("Borrando letra");
            }
        }
    }
}

int verificarMovimiento(char tableroPartida[][COLUMNAS], char tableroJugador[][COLUMNAS], struct DataRecibida *movimiento, char letra) {
    if (tableroPartida[movimiento->fila][movimiento->columna] == letra) {
        tableroJugador[movimiento->fila][movimiento->columna] = letra;
        return 1;
    } else {
        tableroJugador[movimiento->fila][movimiento->columna] = tableroPartida[movimiento->fila][movimiento->columna];
        return 0;
    }
}

void limpiarMemoria(struct MemoriaCompartida *memoria){
    memoria->cantMovExitosos=0;
    memoria->partidaEnProgreso=0;
    memoria->movimiento.fila=0;
    memoria->movimiento.columna=0;
}

void handle_sigint(int sig) {
    printf("SIGINT recibido. Ignorando.\n");
    if(esperandoSem == 1){
        sem_wait(sem_cliente); //En todo el codigo solo espera a sem_cliente, asumo que se esperaba a este mismo.
        esperandoSem=0;
    }
}

void handle_sigusr1(int sig) {
        puts("SIGUSR1 recibido");
    if(memoria->partidaEnProgreso == 1){
        puts("Error, existe una partida en progreso");
        if(esperandoSem == 1){
            sem_wait(sem_cliente); //En todo el codigo solo espera a sem_cliente, asumo que se esperaba a este mismo.
            esperandoSem=0;
        }
    }
    else{
        puts("Cerrando servidor....");
        sem_close(sem_cliente);
        sem_unlink(SEM_NAME_CLIENTE);

        sem_close(sem_sv);
        sem_unlink(SEM_NAME_SV);

        sem_close(sem_partida);
        sem_unlink(SEM_NAME_PARTIDA);

        shmdt(memoria);
        shmctl(shmIdentificador, IPC_RMID, NULL);

        puts("Servidor cerrado satisfactoriamente!!");
        exit(EXIT_SUCCESS);
    }
}


int main() {
    signal(SIGINT, handle_sigint);
    signal(SIGUSR1, handle_sigusr1);
    key_t shmKey = ftok(SHM_PATH, SHM_INT);
    shmIdentificador = shmget(shmKey, sizeof(struct MemoriaCompartida), 0666 | IPC_CREAT);
    memoria = (struct MemoriaCompartida *) shmat (shmIdentificador, 0,0);
    sem_sv = sem_open(SEM_NAME_SV, O_CREAT, 0666, 0);
    sem_cliente = sem_open(SEM_NAME_CLIENTE, O_CREAT, 0666, 0);
    sem_partida = sem_open(SEM_NAME_PARTIDA, O_CREAT, 0666, 0);

    while (1) {
        char tableroPartida[FILAS][COLUMNAS];
        limpiarMemoria(memoria);
        puts("Esperando conexión del cliente...");
        sem_post(sem_partida);
        esperandoSem=1;
        sem_wait(sem_cliente); // rx 1 cliente
        esperandoSem=0;
        puts("Cliente conectado");

        memoria->partidaEnProgreso = 1;
        crearTablero(tableroPartida);
        inicializarTablero(memoria->tableroJugador);
        mostrarTablero(tableroPartida);
        memoria->cantMovExitosos = 0;
        

        while (memoria->cantMovExitosos<8) {
            char letra;
            int movExitoso;

            puts("Esperando primer movimiento");
            sem_post(sem_sv); // tx 1 servidor

            esperandoSem=1;
            sem_wait(sem_cliente); // rx 2 cliente
            esperandoSem=0;
            puts("Primer movimiento recibido");

            if(!memoria->partidaEnProgreso){
                puts("El cliente finalizo la partida!");
                puts("Reiniciando partida...");
                break;
            }
            letra=tableroPartida[memoria->movimiento.fila][memoria->movimiento.columna];
            printf("Fila: %d, Columna: %d, Letra: %c \n", memoria->movimiento.fila, memoria->movimiento.columna, letra);
            
            
            revelarLetra(tableroPartida, memoria->tableroJugador, &memoria->movimiento);

            mostrarTablero(tableroPartida);
            mostrarTablero(memoria->tableroJugador);
            
            puts("Enviando tablero con primer movimiento");
            sem_post(sem_sv); // tx 3 servidor

            puts("Espera del segundo movimiento");
            esperandoSem=1;
            sem_wait(sem_cliente); // rx 3 cliente
            esperandoSem=0;

            puts("Segundo movimiento recibido");

            if(!memoria->partidaEnProgreso){
                puts("El cliente finalizo la partida!");
                puts("Reiniciando partida...");
                break;
            }

            printf("Fila: %d, Columna: %d, Letra: %c \n", memoria->movimiento.fila, memoria->movimiento.columna, letra);
            puts("Enviando tablero con segundo movimiento");
            movExitoso=verificarMovimiento(tableroPartida, memoria->tableroJugador, &memoria->movimiento, letra);
            mostrarTablero(memoria->tableroJugador);

            puts("Enviando tablero con segundo movimiento");
            sem_post(sem_sv); // tx 4 servidor         

            puts("Generando conclucion de movimiento");
            if (movExitoso == 0) {
                ocultarLetra(memoria->tableroJugador, letra);
                memoria->tableroJugador[memoria->movimiento.fila][memoria->movimiento.columna] = '-';
                mostrarTablero(tableroPartida);
                mostrarTablero(memoria->tableroJugador);
            } else {
                memoria->cantMovExitosos++;
            }

            
            puts("Esperando confirmacion de recepcion del tablero con segundo movimiento");
            esperandoSem=1;
            sem_wait(sem_cliente); // rx 4 cliente
            esperandoSem=0;
                 
            puts("Enviando tablero con conclusión");
            sem_post(sem_sv);

            puts("Esperando confirmacion de recepcion del tablero con conclucion");
            sem_post(sem_sv);

        }
    puts("Terminó el partido!!");
    }
    return 0;
}