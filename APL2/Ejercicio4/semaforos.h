#include <semaphore.h>
#include <sys/stat.h>
#include <sys/ipc.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <errno.h>
#define S_CLIENTE_CONECTADO "/cliente"
#define S_SERVIDOR_CONECTADO "/servidor"
#define S_TABLERO_ESCRITO "/tablero"
#define S_ENTRADA_USUARIO "/usuario"
#define S_INICIAR_JUEGO "/juegoiniciado"

int P(sem_t *);
int P_tout(sem_t *, int);
int V(sem_t *);
sem_t* iniciarSemaforo(const char* nombre, int valor);