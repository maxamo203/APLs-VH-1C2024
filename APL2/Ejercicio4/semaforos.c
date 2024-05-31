#include "semaforos.h"

int P(sem_t * s){
    return sem_wait(s);
}
int P_tout(sem_t * s, int t){
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) == -1) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }
    ts.tv_sec += t;
    return sem_timedwait(s, &ts);
}
int V(sem_t * s){
    return sem_post(s);
}
sem_t* iniciarSemaforo(const char* nombre, int valor) {
    sem_t* sem = sem_open(nombre, 0);
    if (sem == SEM_FAILED) {
        if (errno == ENOENT) { // Semaphore does not exist
            sem = sem_open(nombre, O_CREAT | O_EXCL, S_IRUSR | S_IWUSR, valor);
            if (sem == SEM_FAILED) {
                perror("Error creating semaphore");
                return NULL;
            } else {
                printf("Creado %s, ", nombre);
            }
        } else {
            perror("Error opening semaphore");
            return NULL;
        }
    } else {
        printf("Ya existe %s, ", nombre);
    }

    int val;
    if (sem_getvalue(sem, &val) == -1) {
        perror("Error getting semaphore value");
    } else {
        printf("Valor actual: %d\n", val);
    }

    return sem;
}