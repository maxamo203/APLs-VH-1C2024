#include <stdlib.h>
#include <stdio.h>
#include "semaforos.h"
#include <semaphore.h>
int main(int argc, char* argv[]){
    sem_unlink(S_INICIAR_JUEGO);
    sem_unlink(S_ENTRADA_USUARIO);
    sem_unlink(S_TABLERO_ESCRITO);
    sem_unlink(S_CLIENTE_CONECTADO);
    sem_unlink(S_SERVIDOR_CONECTADO);
    return 0;
}