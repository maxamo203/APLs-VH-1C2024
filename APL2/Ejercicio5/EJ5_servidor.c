#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include "../Bibliotecas/headers/tablero.h"
#include <pthread.h>
#include <semaphore.h>
#include <signal.h>
#include <errno.h>

typedef struct
{
    int nro;
    int socket;
} parametrosThreads;

pthread_t *tids;
sem_t *semaforosTurnos;
sem_t semaforoAvisados;
int cantJugadores = 3;
int jugadoresConectados = 0;
char * estadoJugadores;
int jugadorActual = 0;

pthread_barrier_t barreraInicio;
pthread_mutex_t mutex;
Tablero tablero;
parametrosThreads *params;
int userInput[2];
char sendBuff[128]; // el sizeof del tablero me da 72, por las dudas le doy el doble

int levantarServer(int puerto);

void enviarTableroActualizado()
{
    pthread_t mitid = pthread_self();
    int ind = 0;
    for (int i = 0; i < cantJugadores; i++)
    {
        if (mitid == tids[i])
        {
            ind = i;
            puts("Encontre tid");
        }
    }
    puts("1");
    char bufferAviso[50];
    int result = recv(params[ind].socket, &bufferAviso, 1, MSG_PEEK | MSG_DONTWAIT);
    if(result == 0){
        puts("AJJAAAA");
        estadoJugadores[ind] = 0;
        jugadoresConectados--;
        sem_post(&semaforoAvisados);
        return;
    }
    sprintf(bufferAviso, "jugador %d dio vuelta %d %d", jugadorActual, userInput[0], userInput[1]);
    if(write(params[ind].socket, sendBuff, sizeof(sendBuff)) <= 0){
        puts("ALGO RAROOOO 1");
    }
    usleep(10000);
    if(write(params[ind].socket, bufferAviso, sizeof(bufferAviso)) <= 0) {
        puts("ALGO RARROOOOO 2");
    }
    puts("Imprimio tablero en otro");
    sem_post(&semaforoAvisados);
}
void *enviarTexto(void *arg)
{
    // struct sigaction sa;
    // sa.sa_handler = enviarTableroActualizado;
    // sa.sa_flags = 0; // Ensure the signal interrupts the open call
    // sigemptyset(&sa.sa_mask);
    // if (sigaction(SIGUSR1, &sa, NULL) == -1) {
    //     perror("sigaction");
    //     exit(EXIT_FAILURE);
    // }
    signal(SIGUSR1, enviarTableroActualizado);
    int socketCom = ((parametrosThreads *)arg)->socket;
    int nro = ((parametrosThreads *)arg)->nro;
    estadoJugadores[nro] = 1;

    char receiveBuffer[30];

    pthread_mutex_lock(&mutex);
    jugadoresConectados++;
    pthread_mutex_unlock(&mutex);
    sprintf(sendBuff, "Esperando jugadores %d/%d...", jugadoresConectados, cantJugadores);
    write(socketCom, sendBuff, strlen(sendBuff));
    int rc = pthread_barrier_wait(&barreraInicio);
    write(socketCom, "JUEGO INICIADO", sizeof("JUEGO INICIADO"));
    while (jugadoresConectados > 0 && !tableroCompleto(&tablero))
    {
        printf("Principio %d\n", nro);
        if (sem_wait(&semaforosTurnos[nro]) == -1)
        {
            puts("Alto ahi compa;ero");
        }
        if(tableroCompleto(&tablero)){
            sem_post(&semaforosTurnos[(nro + 1) % cantJugadores]);
            break;
        }
        printf("%d-----\n", errno);
        if (estadoJugadores[nro])
        { // aunque el cliente se haya desconectado el server mantiene su estructura
            for (int i = 0; i < 2; i++)
            {
                jugadorActual = nro;
                printf("Algo %d\n", i);
                usleep(10000);
                write(socketCom, "TU TURNO", sizeof("TU TURNO"));
                usleep(10000);
                if(read(socketCom, receiveBuffer, sizeof(receiveBuffer)) == 0){ //por si se desconecta el que esta jugando en este memomento
                    puts("Jugador desconectado");
                    pthread_mutex_lock(&mutex);
                    jugadoresConectados--;
                    estadoJugadores[nro] = 0;
                    pthread_mutex_unlock(&mutex);
                    break;
                }
                memcpy(userInput, receiveBuffer, sizeof(receiveBuffer));
                printf("%d %d Ingreso el usuario\n", userInput[1], userInput[0]);
                int res = darVueltaPosicion(&tablero, userInput[1], userInput[0]);
                if(res == 0){ //dio vuelta la misma posicion de antes
                    i--;
                    continue;
                }
                memcpy(sendBuff, &tablero, sizeof(tablero));
                write(socketCom, sendBuff, sizeof(sendBuff));
                // mandar señal a otros hilos para que le informen al usuario
                for (int i = 0; i < cantJugadores; i++)
                {
                    if (i == nro || estadoJugadores[i] == 0)
                        continue; // que no se mande una señal a si mismo o a uno que no esta jugando
                    printf("se;al enviada a %ld, soy %ld\n", tids[i], pthread_self());
                    pthread_kill(tids[i], SIGUSR1);
                }
                for (int i = 0; i < jugadoresConectados - 1; i++)
                {
                    sem_wait(&semaforoAvisados);
                }
                puts("Hasta aca");
            }
        }
        sem_post(&semaforosTurnos[(nro + 1) % cantJugadores]);
    }
    //jugadoresConectados--;
    close(socketCom);
}
// devuelve el FD del socket abierto

int main(int argc, char *argv[])
{

    int server = levantarServer(8080);

    int i = 0;
    tids = malloc(cantJugadores * sizeof(pthread_t));
    params = malloc(cantJugadores * sizeof(parametrosThreads));
    semaforosTurnos = malloc(cantJugadores * sizeof(sem_t));
    pthread_mutex_init(&mutex, NULL);
    sem_init(&semaforoAvisados, 0, 0);
    estadoJugadores = malloc(cantJugadores);
    while(1){
        if (pthread_barrier_init(&barreraInicio, NULL, cantJugadores) != 0)
            {
                perror("pthread_barrier_init");
                return EXIT_FAILURE;
            }
        generarTablero(&tablero);
        for(int i = 0;i<4;i++){
                    for (int j = 0; j < 4; j++)
                    {
                        printf("%c %d-%d\n",tablero.tablero[i][j],i,j);
                    }     
                }
        printf("%li--\n", sizeof(tablero));
        while (i < cantJugadores)
        {
            if (sem_init(&semaforosTurnos[i], 0, (i == 0) ? 1 : 0) != 0)
            {
                perror("sem_init");
                exit(EXIT_FAILURE);
            }
            params[i].socket = accept(server, (struct sockaddr *)NULL, NULL);
            params[i].nro = i;
            pthread_create(&tids[i], NULL, enviarTexto, (void *)&(params[i]));
            i++;
        }
        for (int i = 0; i < cantJugadores; i++)
        {
            pthread_join(tids[i], NULL);
        }
        
        puts("Partida terminada");
        pthread_barrier_destroy(&barreraInicio);
        for(int i =0;i<cantJugadores;i++){
            sem_destroy(&semaforosTurnos[i]);
        }
        i = 0;
        jugadoresConectados = 0;
    }
    



    close(server);
    return 0;
}

int levantarServer(int puerto)
{
    struct sockaddr_in address;
    int opt = 1;
    int server;
    if ((server = socket(AF_INET, SOCK_STREAM, 0)) == 0)
    {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }
    // Configurar el socket para permitir la reutilización de la dirección
    if (setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)))
    {
        perror("setsockopt");
        close(server);
        exit(EXIT_FAILURE);
    }
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(puerto);
    if (bind(server, (struct sockaddr *)&address, sizeof(address)) < 0)
    {
        perror("bind failed");
        close(server);
        exit(EXIT_FAILURE);
    }
    if (listen(server, 3) < 0)
    {
        perror("listen");
        close(server);
        exit(EXIT_FAILURE);
    }
    return server;
}