#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <arpa/inet.h>
#include "../Bibliotecas/headers/tablero.h"
#include "../Bibliotecas/headers/parsearParametros.h"
#include <pthread.h>
#include <semaphore.h>
#include <signal.h>
#include <errno.h>

typedef struct
{
    int nro;
    int socket;
} parametrosThreads;
typedef struct
{
    char nombre[30];
} TNombre;
pthread_t *tids;
sem_t *semaforosTurnos;
sem_t semaforoAvisados;
int cantJugadores;
int jugadoresConectados = 0;
char *estadoJugadores; // guarda los aciertos de cada jugador o -1 si se desconecta
TNombre *nombresJugadores;
int jugadorActual = 0;
int server;
pthread_barrier_t barreraInicio;
pthread_mutex_t mutex;
Tablero tablero;
parametrosThreads *params;
int userInput[2];
char sendBuff[128]; // el sizeof del tablero me da 72, por las dudas le doy el doble

int levantarServer(int puerto);

void mostrarAyuda()
{
    puts("Mostrando AYUDA");
    puts("-p/--puerto --> Indica el puerto donde va a quedar corriendo el servidor");
    puts("-j/--jugadores --> Indica la cantidad de jugadores que va a esperar para iniciar la partida");
}
void terminarServer()
{
   
}
int isNumber(const char *str)
{
    while (*str)
    {
        if (!isdigit(*str))
        {
            return 0; // No es un número
        }
        str++;
    }
    return 1; // Es un número
}
int validarParametros(char *puerto, char *usuarios)
{
    if (puerto == NULL || usuarios == NULL)
    {
        puts("ERROR: Parametros insuficientes, puerto y cantidad de jugadores son requeridos");
        return 0;
    }
    if (!isNumber(puerto) || !isNumber(usuarios))
    {
        puts("ERROR: Tanto el puerto como el usuario deben ser numero enteros");
        return 0;
    }
    if (atoi(puerto) <= 1024)
    {
        puts("ERROR: El puerto debe ser mayor a 1024");
        return 0;
    }
    if (atoi(usuarios) <= 0)
    {
        puts("ERROR: Debe haber al menos un usuario");
        return 0;
    }
}
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
    char bufferAviso[50];
    int result = recv(params[ind].socket, &bufferAviso, 1, MSG_PEEK | MSG_DONTWAIT);
    if (result == 0)
    { // se desconecto uno
        puts("Jugador desconectado");
        estadoJugadores[ind] = -1;
        jugadoresConectados--;
        sem_post(&semaforoAvisados);
        return;
    }
    sprintf(bufferAviso, "[%s] dio vuelta %d %d", nombresJugadores[jugadorActual].nombre, userInput[0], userInput[1]);
    write(params[ind].socket, sendBuff, sizeof(sendBuff));
    usleep(10000);
    write(params[ind].socket, bufferAviso, sizeof(bufferAviso));
    puts("Imprimio tablero en otro");
    sem_post(&semaforoAvisados);
}
void enviarResultados(int socket)
{
    char bufferSend[2000];
    char bufferNombre[30];
    strcat(bufferSend, "RESULTADOS:\n");
    for (int i = 0; i < jugadoresConectados; i++)
    {
        strcat(bufferSend, nombresJugadores[i].nombre);
        strcat(bufferSend, ": ");
        sprintf(bufferNombre, "%d\n", estadoJugadores[i]); // Convertir el entero a una cadena
        strcat(bufferSend, estadoJugadores[i] < 0 ? "0" : bufferNombre);
    }
    write(socket, bufferSend, sizeof(bufferSend));
}
void *enviarTexto(void *arg)
{
    signal(SIGUSR1, enviarTableroActualizado);
    int socketCom = ((parametrosThreads *)arg)->socket;
    int nro = ((parametrosThreads *)arg)->nro;
    estadoJugadores[nro] = 0;

    char receiveBuffer[30];

    pthread_mutex_lock(&mutex);
    jugadoresConectados++;
    pthread_mutex_unlock(&mutex);
    sprintf(sendBuff, "Esperando jugadores %d/%d...", jugadoresConectados, cantJugadores);
    write(socketCom, sendBuff, strlen(sendBuff));
    int rc = pthread_barrier_wait(&barreraInicio);
    write(socketCom, "JUEGO INICIADO", sizeof("JUEGO INICIADO"));
    read(socketCom, nombresJugadores[nro].nombre, 30); // recibe el nombre
    while (jugadoresConectados > 0 && !tableroCompleto(&tablero))
    {
        printf("Principio %d\n", nro);
        sem_wait(&semaforosTurnos[nro]);
        if (tableroCompleto(&tablero))
        {
            sem_post(&semaforosTurnos[(nro + 1) % cantJugadores]);
            break;
        }
        printf("%d-----\n", errno);
        if (estadoJugadores[nro] >= 0)
        { // aunque el cliente se haya desconectado el server mantiene su estructura
            for (int i = 0; i < 2; i++)
            {
                jugadorActual = nro;
                usleep(10000);
                write(socketCom, "TU TURNO", sizeof("TU TURNO"));
                usleep(10000);
                if (read(socketCom, receiveBuffer, sizeof(receiveBuffer)) == 0)
                { // por si se desconecta el que esta jugando en este memomento
                    puts("Jugador desconectado");
                    pthread_mutex_lock(&mutex);
                    jugadoresConectados--;
                    estadoJugadores[nro] = -1;
                    pthread_mutex_unlock(&mutex);
                    break;
                }
                memcpy(userInput, receiveBuffer, sizeof(receiveBuffer));
                printf("%d %d Ingreso el usuario\n", userInput[1], userInput[0]);
                int res = darVueltaPosicion(&tablero, userInput[1], userInput[0]);
                if (res == 0)
                { // dio vuelta la misma posicion de antes
                    i--;
                    continue;
                }
                else if (res == 2)
                { // si acierta
                    estadoJugadores[nro]++;
                }
                memcpy(sendBuff, &tablero, sizeof(tablero));
                write(socketCom, sendBuff, sizeof(sendBuff));
                // mandar señal a otros hilos para que le informen al usuario
                for (int i = 0; i < cantJugadores; i++)
                {
                    if (i == nro || estadoJugadores[i] == -1)
                        continue; // que no se mande una señal a si mismo o a uno que no esta jugando
                    printf("señal enviada a %ld, soy %ld\n", tids[i], pthread_self());
                    pthread_kill(tids[i], SIGUSR1);
                }
                for (int i = 0; i < jugadoresConectados - 1; i++) // espero que todos los hilos hayan mandado la señal
                {
                    sem_wait(&semaforoAvisados);
                }
            }
        }
        sem_post(&semaforosTurnos[(nro + 1) % cantJugadores]);
    }
    if (estadoJugadores[nro] >= 0)
    {
        enviarResultados(socketCom);
    }
    close(socketCom);
}

int main(int argc, char *argv[])
{
    struct sigaction sa;
    sa.sa_handler = terminarServer;
    sa.sa_flags = 0; // Ensure the signal interrupts the open call
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIGINT, &sa, NULL) == -1)
    {
        perror("sigaction");
        exit(EXIT_FAILURE);
    }

    char *puerto = NULL, *usuarios = NULL, *help = NULL;
    char *opcionesLargas[] = {"puerto", "jugadores", "help"};
    char **variables[] = {&puerto, &usuarios, &help};
    parsearParametros(argv, argc, "p:j:h", opcionesLargas, 3, variables);
    if (help)
    {
        mostrarAyuda();
        return 0;
    }
    if (!validarParametros(puerto, usuarios))
    {
        return 1;
    }
    server = levantarServer(atoi(puerto));
    cantJugadores = atoi(usuarios);

    tids = malloc(cantJugadores * sizeof(pthread_t));
    params = malloc(cantJugadores * sizeof(parametrosThreads));
    semaforosTurnos = malloc(cantJugadores * sizeof(sem_t));
    estadoJugadores = malloc(cantJugadores);
    nombresJugadores = malloc(cantJugadores * (sizeof(TNombre)));
    pthread_mutex_init(&mutex, NULL);
    sem_init(&semaforoAvisados, 0, 0);
    char señal = 0;
    int i = 0;
    while (1)
    {
        if (pthread_barrier_init(&barreraInicio, NULL, cantJugadores) != 0)
        {
            perror("pthread_barrier_init");
            return EXIT_FAILURE;
        }
        generarTablero(&tablero);
        for (int i = 0; i < 4; i++)
        {
            for (int j = 0; j < 4; j++)
            {
                printf("%c %d-%d\n", tablero.tablero[i][j], i, j);
            }
        }
        while (i < cantJugadores)
        {
            if (sem_init(&semaforosTurnos[i], 0, (i == 0) ? 1 : 0) != 0)
            {
                perror("sem_init");
                exit(EXIT_FAILURE);
            }
            if ((params[i].socket = accept(server, (struct sockaddr *)NULL, NULL)) == -1)
            {
                señal = 1;
                break;
            }
            params[i].nro = i;
            pthread_create(&tids[i], NULL, enviarTexto, (void *)&(params[i]));
            i++;
        }
        if (!señal)
            for (int i = 0; i < cantJugadores; i++)
            {
                if (pthread_join(tids[i], NULL) != 0)
                { // hubo interrupcion
                    señal = 1;
                    break;
                }
            }

        puts("Partida terminada");
        pthread_barrier_destroy(&barreraInicio);
        for (int i = 0; i < cantJugadores; i++)
        {
            sem_destroy(&semaforosTurnos[i]);
        }
        if (señal)
        {
            break;
        }
        i = 0;
        jugadoresConectados = 0;
    }
    puts("Saliendo...");
    freeParametros(3, variables);
    free(nombresJugadores);
    free(estadoJugadores);
    free(semaforosTurnos);
    free(params);
    free(tids);
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
    // configura el socket para permitir la reutilización del puerto
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