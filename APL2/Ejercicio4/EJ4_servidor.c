#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <string.h>
#include "../Bibliotecas/headers/tablero.h"
#include "semaforos.h"
#include <signal.h>

volatile sig_atomic_t signal_caught = 0;

void manejarusr2(){
    signal_caught = SIGUSR2;
}
void manejarusr1(){
    signal_caught = SIGUSR1;
}
void interrupcion(){
    printf("\rNo se puede interrumpir\n");
}
int main(int argc, char* argv[]){
    //TODO validar que no haya otro servidor
    if(signal(SIGINT, interrupcion) == SIG_ERR) {
        perror("No se pudo establecer el manejador de señal");
        return 1;
    }
    struct sigaction sa;
    sa.sa_handler = manejarusr2;
    sa.sa_flags = 0; // Ensure the signal interrupts the open call
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIGUSR2, &sa, NULL) == -1) {
        perror("sigaction");
        exit(EXIT_FAILURE);
    }

    struct sigaction sa2;
    sa2.sa_handler = manejarusr1;
    sa2.sa_flags = 0; // Ensure the signal interrupts the open call
    sigemptyset(&sa2.sa_mask);
    if (sigaction(SIGUSR1, &sa2, NULL) == -1) {
        perror("sigaction");
        exit(EXIT_FAILURE);
    }

    Tablero tablero;
    sem_t* s_cliente,*s_servidor, *s_tableroEscrito, *s_entradaUsuario, *s_juegoIniciado;
    //memoria compartida para el tablero
    key_t key = ftok("tablero1", 68);
    if (key == -1) {
        perror("Error al generar la clave de memoria compartida para el tablero");
        exit(EXIT_FAILURE);
    }
    int shmid1 = shmget(key, sizeof(Tablero), 0666 | IPC_CREAT);
    if (shmid1 == -1) {
        perror("Error al crear memoria compartida para el tablero");
        exit(EXIT_FAILURE);
    }
    Tablero* shtab = (Tablero*)shmat(shmid1, (void*)0, 0);
    if (shtab == (void*)-1) {
        perror("Error al adjuntar memoria compartida para el tablero");
        exit(EXIT_FAILURE);
    }


    //memoria compartida para la entrada del usuario
    key_t key2 = ftok("input1", 68);
    int shmid2 = shmget(key2, 3*sizeof(int), 0666 | IPC_CREAT); //un array de tres posiciones para las entradas [x,y] y el pid del servidor
    int* shminput = (int*)shmat(shmid2, (void*)0, 0);
    s_cliente = iniciarSemaforo(S_CLIENTE_CONECTADO, 0);
    s_servidor = iniciarSemaforo(S_SERVIDOR_CONECTADO, 0);
    s_tableroEscrito = iniciarSemaforo(S_TABLERO_ESCRITO, 0);
    s_entradaUsuario = iniciarSemaforo(S_ENTRADA_USUARIO, 0);
    s_juegoIniciado = iniciarSemaforo(S_INICIAR_JUEGO, 0);
     //pongo el pid del servidor en memoria compartida para que el cliente sepa donde mandar la señal de fin
    while(1){
        puts("Esperando cliente...");
        shminput[2] = (int)getpid();
        if(P(s_cliente) == -1){
            if(signal_caught == SIGUSR2){
                perror("Algo");
                puts("Cliente No se conecto");
                continue;
            }else{
                puts("Saliendo");
                break;
            }
        }
        V(s_servidor);
        puts("Cliente conectado");
        //shminput[2] = getpid();
        //puts("1");
        if(P(s_juegoIniciado) == -1){
            if(signal_caught == SIGUSR2){
                perror("Algo");
                puts("Cliente No se conecto");
                continue;
            }else{
                puts("Saliendo");
                break;
            }
        }
        //puts("1");
        generarTablero(&tablero);
        for(int i = 0;i<4;i++){
                for (int j = 0; j < 4; j++)
                {
                    printf("%c %d-%d\n",tablero.tablero[i][j],i,j);
                }     
            }
        //puts("1");
        escribirEnMemoria(&tablero, shtab);
        //puts("1");
        V(s_tableroEscrito);
        iniciarJuego(&tablero);
        puts("Juego iniciado");
        int x = 0,y = 0;
        char clientePerdido = 0;
        while (! tableroCompleto(&tablero) && x != -1 && y != -1)
        {
            if(P(s_entradaUsuario) == -1){
                if(signal_caught == SIGUSR2){
                    puts("Partida temrinada");
                    clientePerdido = 1;
                    break;
                }else{
                    puts("Partida en curso, no se puede finalizar");
                    continue;
                }
            }
            printf("Usuaro dijo x=%d y=%d\n", shminput[0], shminput[1]);
            darVueltaPosicion(&tablero, shminput[0], shminput[1]);
            x = shminput[0];
            y = shminput[1];
            escribirEnMemoria(&tablero, shtab);
            printf("Dado vuelta\n");
            V(s_tableroEscrito);
        }
        if(clientePerdido){
            continue;
        }
        finalizarJuego(&tablero);
        escribirEnMemoria(&tablero, shtab);
        V(s_tableroEscrito);
        puts("Juego finalizado");
    }

    sem_close(s_juegoIniciado);
    sem_close(s_entradaUsuario);
    sem_close(s_tableroEscrito);
    sem_close(s_cliente);
    sem_close(s_servidor);
    sem_unlink(S_INICIAR_JUEGO);
    sem_unlink(S_ENTRADA_USUARIO);
    sem_unlink(S_TABLERO_ESCRITO);
    sem_unlink(S_CLIENTE_CONECTADO);
    sem_unlink(S_SERVIDOR_CONECTADO);
    // destroy the shared memory
    shmctl(shmid1, IPC_RMID, NULL);
    shmctl(key, IPC_RMID, NULL);
    shmctl(shmid2, IPC_RMID, NULL);
    shmctl(key2, IPC_RMID, NULL);
    return 0;
}