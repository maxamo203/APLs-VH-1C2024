#include <stdio.h>
#include <stdlib.h>
#include <semaphore.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <errno.h>
#include "../Bibliotecas/headers/tablero.h"
#include "semaforos.h"
#include <signal.h>
void limpiarBufferEntrada() {
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}
void interrupcion(){
    printf("\rNo se puede interrumpir\n");
}
int main(int argc, char* argv[]){
    if(signal(SIGINT, interrupcion) == SIG_ERR) {
        perror("No se pudo establecer el manejador de señal");
        return 1;
    }
    //TODO validar que no haya otro cliente
    sem_t* s_cliente,*s_servidor, *s_tableroEscrito, *s_entradaUsuario, *s_juegoIniciado;
    //memoria compartida para el tablero
    key_t key = ftok("tablero1", 68);
    int shmid1 = shmget(key, sizeof(Tablero), 0666 | IPC_CREAT);
    Tablero* shtab = (Tablero*)shmat(shmid1, (void*)0, 0);
    //memoria compartida para la entrada del usuario
    key_t key2 = ftok("input1", 68);
    int shmid2 = shmget(key2, 3*sizeof(int), 0666 | IPC_CREAT); //un array de dos posiciones para las entradas [x,y]
    int* shminput = (int*)shmat(shmid2, (void*)0, 0);
    s_cliente = iniciarSemaforo(S_CLIENTE_CONECTADO, 0);
    s_servidor = iniciarSemaforo(S_SERVIDOR_CONECTADO, 0);
    s_tableroEscrito = iniciarSemaforo(S_TABLERO_ESCRITO, 0);
    s_entradaUsuario = iniciarSemaforo(S_ENTRADA_USUARIO, 0);
    s_juegoIniciado = iniciarSemaforo(S_INICIAR_JUEGO, 0);
    
    int input[2];
    char bufferRespuesta[5];
    char res;
    char finalizaMal = 0;
    while(1){
        V(s_cliente);
        puts("Esperando servidor...");
        P_tout(s_servidor, 5);
        if(errno == ETIMEDOUT){
            puts("No se encontro servidor en el tiempo especificado, saliendo...");
            break;
        }
        puts("Servidor conectado");
        puts("Quieres jugar un juego? (y/n)");
        scanf("%s", &res);
        printf("%d ", res);
        limpiarBufferEntrada();

        if (res == 'n') {
            puts("saliendo");
            break;
        }
        // puts("Aca toi");
        V(s_juegoIniciado);
        P_tout(s_tableroEscrito,2);
        if(errno == ETIMEDOUT){
            puts("servidor desconectado, saliendo...");
            break;;
        }
        char tout = 0;
        while(! tableroCompleto(shtab)){
            // for(int i = 0;i<4;i++){
            //     for (int j = 0; j < 4; j++)
            //     {
            //         printf("%c %d\n",shtab->tablero[i][j],shtab->descubiertos[i][j]);
            //     }     
            // }
            imprimirTablero(shtab);
            printf("Ingresa entrada (x y)/(-1 -1) para salir al menu: ");
            scanf("%d %d", &input[1], &input[0]);
            if(input[0] == -1 && input[1] == -1){
                finalizaMal = 1;
                printf("%d PID\n", shminput[2]);
                kill(shminput[2], SIGUSR2);
                break;
            }
            shminput[0] = input[0];
            shminput[1] = input[1];
            V(s_entradaUsuario);
            P_tout(s_tableroEscrito,2);
            if(errno == ETIMEDOUT){
                puts("servidor desconectado, saliendo...");
                tout = 1;
                break;
            }
        }
        if(tout) break;
        if(!finalizaMal){
            //V(s_finalizaMal)
            P_tout(s_tableroEscrito,2);
            if(errno == ETIMEDOUT){
                puts("servidor desconectado, saliendo...");
                break;
            }   
            imprimirTablero(shtab);
            puts("Juego finalizado");
            printf("Tiempo en resolver %.2f\n", shtab->tfin-shtab->tinicio);
        }
        else{
            puts("Saliendo del juego");
        }
    }
    printf("%d PID\n", shminput[2]);
    kill(shminput[2], SIGUSR2);
    //V(s_cliente)
    sem_trywait(s_cliente); //para que si termina restablezca los semaforo
    sem_trywait(s_entradaUsuario);
    sem_trywait(s_juegoIniciado);

    sem_close(s_juegoIniciado);
    sem_close(s_entradaUsuario);
    sem_close(s_tableroEscrito);
    sem_close(s_cliente);
    sem_close(s_servidor);
    // sem_unlink(S_INICIAR_JUEGO);
    // sem_unlink(S_ENTRADA_USUARIO);
    // sem_unlink(S_TABLERO_ESCRITO);
    // sem_unlink(S_CLIENTE_CONECTADO);
    // sem_unlink(S_SERVIDOR_CONECTADO);
    // shmctl(shmid1, IPC_RMID, NULL);
    // shmctl(shmid2, IPC_RMID, NULL);
    return 0;
}