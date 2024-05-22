#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <getopt.h>

void mostrar_ayuda() {
    printf("Uso: programa [opciones]\n");
    printf("Opciones:\n");
    printf("  -h, --help                 Mostrar esta ayuda y salir\n");
    printf("  -d, --directorio <ruta>    Especificar el directorio\n");
}

void Mensaje( int pid, int ppid);
int main(int argc, char *argv[]){
    int opt;
    char *directorio = NULL;

    // Estructura para las opciones largas
    struct option long_options[] = {
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    // Procesar los argumentos
    while ((opt = getopt_long(argc, argv, "hd:", long_options, NULL)) != -1) {
        switch (opt) {
            case 'h':
                mostrar_ayuda();
                exit(EXIT_SUCCESS);
            default:
                mostrar_ayuda();
                exit(EXIT_FAILURE);
        }
    }

    int pid = fork();
    int pid2 = -1;
    int pid3 = -1;
    if (pid == 0){
        Mensaje(getpid(), getppid());
        pid2 = fork();
        if (pid2 == 0){
            Mensaje(getpid(), getppid()); //aca hay condicion de carrera, puede decir el PID del padre o del proceso INIT, depende de si termina el padre antes de que ejecute el mensaje
        }
        else{
            exit(2); //el proceso padre termina, dejando al hijo "huerfano", lo adopta init
            //wait(NULL);
        }
    }
    else{
        Mensaje(getpid(), getppid());
        pid3 = fork();
        if(pid3 == 0){
            Mensaje(getpid(), getppid());
            exit(0); //el proceso hijo termina pero el padre no lo reconoce (espera)
        }
        else{
            int pid4 = fork();
            if(pid4 == 0){
                Mensaje(getpid(), getppid());
                int pid5 = fork();
                if(pid5 == 0){
                    Mensaje(getpid(), getppid());
                }else{
                    int pid6 = fork();
                    if(pid6 == 0){
                        Mensaje(getpid(), getppid());
                    }
                    else{
                        int pid7 = fork();
                        if(pid7 == 0){
                            Mensaje(getpid(), getppid());
                            int pid8 = fork();
                            if (pid8 == 0){
                                Mensaje(getpid(), getppid());
                            }else{
                                wait(NULL);
                            }
                        }else{
                            waitpid(pid5, NULL, 0);
                            waitpid(pid6, NULL, 0);
                            waitpid(pid7, NULL, 0);
                        }
                    }
                }



            }else{

                waitpid(pid, NULL, 0);
                waitpid(pid4, NULL, 0);
                
            }
        }
    }
    
    getchar();
    printf("Yo era %d\n", getpid());
    return 0;
}

void Mensaje( int pid, int ppid){
    printf("Soy el proceso Ejercicio1 con PID %d, mi padre es %d\n", pid, ppid);
}