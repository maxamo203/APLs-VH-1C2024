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


void mostrarTablero(char tablero[][COLUMNAS]) {
    for (int i = 0; i < COLUMNAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            printf("%c ", tablero[i][j]);
        }
        printf("\n");
    }
    puts(" ");
}

void handle_sigint(int sig){
    printf("SIGINT recibido. Ignorando.\n");
}

int main() {
    signal(SIGINT, handle_sigint);
    key_t shmKey = ftok(SHM_PATH, SHM_INT);
    if (shmKey == -1) {
        perror("Error al obtener la clave de la memoria compartida");
        exit(EXIT_FAILURE);
    }

    int shmIdentificador = shmget(shmKey, sizeof(struct MemoriaCompartida), 0666 | IPC_CREAT);
    if (shmIdentificador == -1) {
        perror("Error al obtener el identificador de la memoria compartida");
        exit(EXIT_FAILURE);
    }

    struct MemoriaCompartida *memoria = (struct MemoriaCompartida *)shmat(shmIdentificador, NULL, 0);
    if (memoria == (void *)-1) {
        perror("Error al adjuntar la memoria compartida");
        exit(EXIT_FAILURE);
    }

    sem_t *sem_sv = sem_open(SEM_NAME_SV, 0);
    if (sem_sv == SEM_FAILED) {
        perror("Error al abrir el semáforo del servidor");
        exit(EXIT_FAILURE);
    }

    sem_t *sem_cliente = sem_open(SEM_NAME_CLIENTE, 0);
    if (sem_cliente == SEM_FAILED) {
        perror("Error al abrir el semáforo del cliente");
        exit(EXIT_FAILURE);
    }

    sem_t *sem_partida = sem_open(SEM_NAME_PARTIDA, 0);
    if (sem_partida == SEM_FAILED) {
        perror("Error al abrir el semáforo de la partida");
        exit(EXIT_FAILURE);
    }
    clock_t start_time = clock();
    puts("Esperando servidor");
    sem_wait(sem_partida); 

    puts("Servidor conectado!!");
    sem_post(sem_cliente); // tx 1 cliente

    puts("Esperando tablero");
    sem_wait(sem_sv); // rx 1 servidor
    mostrarTablero(memoria->tableroJugador);
    while (memoria->cantMovExitosos < 8) {
        do {
            printf("Ingrese la fila (1-4) (0 para finalizar): ");
            scanf("%d", &memoria->movimiento.fila);
            if(memoria->movimiento.fila == 0){
                printf("Seguro que quiere finalizar la partida? (0 para finalizar)");
            }
            else{
                printf("Ingrese la columna (1-4): ");
            }
            scanf("%d", &memoria->movimiento.columna);

            if(memoria->movimiento.fila == 0 && memoria->movimiento.fila == 0){
                puts("Finalizando partida...");
                memoria->partidaEnProgreso=0;
                break;
            }

            memoria->movimiento.fila--;
            memoria->movimiento.columna--;
        } while (memoria->movimiento.fila >= FILAS || memoria->movimiento.columna >= COLUMNAS ||
                memoria->movimiento.fila < 0 || memoria->movimiento.columna < 0 ||
                memoria->tableroJugador[memoria->movimiento.fila][memoria->movimiento.columna] != '-');
        
        if(!memoria->partidaEnProgreso){
            puts("Enviando fin de partida...");
            sem_post(sem_cliente); 
            break;
        }

        puts("Enviando primer movimiento");
        sem_post(sem_cliente); // tx 2 cliente

        puts("Esperando tablero con primer movimiento");
        sem_wait(sem_sv); // rx 3 servidor
        sleep(1);

        mostrarTablero(memoria->tableroJugador);
        
        do {
            printf("Ingrese la fila (1-4) (0 para finalizar): ");
            scanf("%d", &memoria->movimiento.fila);
            if(memoria->movimiento.fila == 0){
                printf("Seguro que quiere finalizar la partida? (0 para finalizar)");
            }
            else{
                printf("Ingrese la columna (1-4): ");
            }
            scanf("%d", &memoria->movimiento.columna);

            if(memoria->movimiento.fila == 0 && memoria->movimiento.fila == 0){
                puts("Finalizando partida...");
                memoria->partidaEnProgreso=0;
                break;
            }

            memoria->movimiento.fila--;
            memoria->movimiento.columna--;
        } while (memoria->movimiento.fila >= FILAS || memoria->movimiento.columna >= COLUMNAS ||
                memoria->movimiento.fila < 0 || memoria->movimiento.columna < 0 ||
                memoria->tableroJugador[memoria->movimiento.fila][memoria->movimiento.columna] != '-');
        
        if(!memoria->partidaEnProgreso){
            puts("Enviando fin de partida...");
            sem_post(sem_cliente); 
            break;
        }

        puts("Enviando segundo movimiento");
        sem_post(sem_cliente); // rx 3 cliente
        puts("Esperando tablero con segundo movimiento");
        sem_wait(sem_sv); // rx 4 servidor

        mostrarTablero(memoria->tableroJugador);
        puts("Esperando tablero con conclusión");
        
        sem_post(sem_cliente); // tx 4 cliente  
        sem_wait(sem_sv); //rx 1 servidor
        mostrarTablero(memoria->tableroJugador);
    }

    if(memoria->cantMovExitosos == 8){
        puts("¡Felicidades! Ha completado el memotest.");
    }

    sem_close(sem_cliente);
    sem_close(sem_sv);
    sem_close(sem_partida);

    shmdt(memoria);

    printf("Cliente cerrando");
    return 0;
}