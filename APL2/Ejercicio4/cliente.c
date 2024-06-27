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
    pid_t pidCliente;   
};

void limpiarBufferEntrada() {
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}

void mostrarTablero(char tablero[][COLUMNAS]) {
    printf("\033[2J");//borrar pantalla
    printf("\033[H"); //mover arriba
    printf("  1 2 3 4\n");
    for (int i = 0; i < COLUMNAS; i++) {
        printf("%d ", i+1);
        for (int j = 0; j < COLUMNAS; j++) {
            printf("%c ", tablero[i][j]);
        }
        printf("\n");
    }
    puts(" ");
}

//Ignora la señales SIGINT (Ctrl + c)
void handle_sigint(int sig){
    puts("SIGINT recibido. Ignorando.\n");
}

void imprimirSem(sem_t *semaforo){
    int valor;
    sem_getvalue(semaforo, &valor);
    printf("Valor del semaforo %d\n", valor);
}

sem_t *sem_sv;
sem_t *sem_cliente;
sem_t *sem_partida;
struct MemoriaCompartida *memoria;

void handle_sigterm(int sig){
    int valor;
    sem_getvalue(sem_cliente, &valor);
    memoria->partidaEnProgreso=0;
    //Evalua si el servidor esta esperando una respuesta
    if (valor==0){
        puts("Finalizando partida...");
        sem_post(sem_cliente);
        puts("Enviando confirmacion de fin de partida");
        sem_post(sem_cliente);
    }
    
    //Cierre de referencia a semaforos
    sem_close(sem_cliente);
    sem_close(sem_sv);
    sem_close(sem_partida);

    //Cierre de referencia a memoria compartida
    shmdt(memoria);
    puts("Cliente cerrado!!");
    exit(EXIT_SUCCESS);
}

int main() {
    signal(SIGINT, handle_sigint);
    signal(SIGTERM, handle_sigterm);

    key_t shmKey = ftok(SHM_PATH, SHM_INT);
    if (shmKey == -1) {
        puts("Error al obtener la clave de la memoria compartida");
        exit(EXIT_FAILURE);
    }

    int shmIdentificador = shmget(shmKey, sizeof(struct MemoriaCompartida), 0666 | IPC_CREAT);
    if (shmIdentificador == -1) {
        puts("Error al obtener el identificador de la memoria compartida");
        exit(EXIT_FAILURE);
    }

    memoria = (struct MemoriaCompartida *)shmat(shmIdentificador, NULL, 0);
    if (memoria == (void *)-1) {
        shmctl(shmIdentificador, IPC_RMID, NULL);
        puts("Error al adjuntar la memoria compartida");
        exit(EXIT_FAILURE);
    }

    sem_sv = sem_open(SEM_NAME_SV, 0);
    if (sem_sv == SEM_FAILED) {
        shmdt(memoria);
        shmctl(shmIdentificador, IPC_RMID, NULL);
        puts("Error al abrir el semáforo del servidor, el servidor se encuentra apagado");
        exit(EXIT_FAILURE);
    }

    sem_cliente = sem_open(SEM_NAME_CLIENTE, 0);
    if (sem_cliente == SEM_FAILED) {
        shmdt(memoria);
        shmctl(shmIdentificador, IPC_RMID, NULL);
        puts("Error al abrir el semáforo del cliente");
        exit(EXIT_FAILURE);
    }

    sem_partida = sem_open(SEM_NAME_PARTIDA, 0);
    if (sem_partida == SEM_FAILED) {
        shmdt(memoria);
        shmctl(shmIdentificador, IPC_RMID, NULL);
        perror("Error al abrir el semáforo de la partida");
        exit(EXIT_FAILURE);
    }
    //Reloj para contar la duracion de la partida
    time_t tiempoInicio = time(NULL), tiempoFin;

    puts("Esperando servidor");
    sem_wait(sem_partida); 
    memoria->pidCliente=getpid();
    puts("Servidor conectado!!");
    sem_post(sem_cliente); // tx 1 cliente

    puts("Esperando tablero");
    //imprimirSem(sem_sv);
    sem_wait(sem_sv); // rx 1 servidor
    //imprimirSem(sem_sv);
    mostrarTablero(memoria->tableroJugador);
    while (memoria->cantMovExitosos < 8) {
        do {
            limpiarBufferEntrada();
            
            
            puts("Ingrese la fila (1-4) (0 para finalizar): ");
            scanf("%d", &memoria->movimiento.fila);
            
            if(memoria->movimiento.fila == 0){
                puts("Seguro que quiere finalizar la partida? (0 para finalizar)");
            }
            else{
                puts("Ingrese la columna (1-4): ");
            }
            scanf("%d", &memoria->movimiento.columna);

            if(memoria->movimiento.fila == 0 && memoria->movimiento.columna == 0){
                puts("Finalizando partida...");
                memoria->partidaEnProgreso=0;
                break;
            }
            //Resto uno para enviar bien las referencias al servidor
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
        //imprimirSem(sem_sv);
        sem_wait(sem_sv); // rx 3 servidor
        if(!memoria->partidaEnProgreso){
            puts("El servidor finalizo la partida!");
            break;
        }
        //imprimirSem(sem_sv);
        
        mostrarTablero(memoria->tableroJugador);
        
        do {
            limpiarBufferEntrada();
            puts("Ingrese la fila (1-4) (0 para finalizar): ");
            
            scanf("%d", &memoria->movimiento.fila);
            
            if(memoria->movimiento.fila == 0){
                puts("Seguro que quiere finalizar la partida? (0 para finalizar)");
            }
            else{
                puts("Ingrese la columna (1-4): ");
            }
            scanf("%d", &memoria->movimiento.columna);

            if(memoria->movimiento.fila == 0 && memoria->movimiento.columna == 0){
                puts("Finalizando partida...");
                memoria->partidaEnProgreso=0;
                break;
            }
            //Resto uno para enviar bien las referencias al servidor
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
        //imprimirSem(sem_sv);
        sem_wait(sem_sv); // rx 4 servidor
        if(!memoria->partidaEnProgreso){
            puts("El servidor finalizo la partida!");
            break;
        }
        //imprimirSem(sem_sv);
        mostrarTablero(memoria->tableroJugador);

        puts("Enviando confirmacion de recepcion del tablero con segundo movimiento");

        sem_post(sem_cliente); // tx 4 cliente
        
        puts("Esperando tablero con conclusión");
        //imprimirSem(sem_sv);
        sleep(1); //tiempo para que el jugador vea el segundo movimiento hecho
        sem_wait(sem_sv); //rx 5 servidor
        if(!memoria->partidaEnProgreso){
            puts("El servidor finalizo la partida!");
            break;
        }
        //imprimirSem(sem_sv);
        puts("Tablero con conclusión recibido");
        mostrarTablero(memoria->tableroJugador);
        
        puts("Enviando confirmacion de recepcion del tablero con conclucion");

        sem_post(sem_cliente);
        
    }

    if(memoria->cantMovExitosos >= 8){
        puts("¡Felicidades! Ha completado el memotest.");
    }

    puts("Enviando confirmacion de fin de partida");
    sem_post(sem_cliente);

    //Cierre de referencia a semaforos
    sem_close(sem_cliente);
    sem_close(sem_sv);
    sem_close(sem_partida);

    //Cierre de referencia a memoria compartida
    shmdt(memoria);

    //se registra el tiempo final, se hace la diferencia y se muestra por pantalla
    tiempoFin = time(NULL);
    double tiempoTranscurrido = (double)(tiempoFin - tiempoInicio);
    printf("La partida a durado: %.2f segundos\n", tiempoTranscurrido);
    printf("Cliente cerrando\n");
    return 0;
}
