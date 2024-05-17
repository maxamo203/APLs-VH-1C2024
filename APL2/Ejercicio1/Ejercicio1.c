#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
void Mensaje( int pid, int ppid);
int main(){
    
    int pid = fork();
    int pid2 = -1;
    int pid3 = -1;
    if (pid == 0){
        Mensaje(getpid(), getppid());
        pid2 = fork();
        if (pid2 == 0){
            Mensaje(getpid(), getppid());
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
    printf("Yo era %d o %d o %d\n", pid, pid2, pid3);
    return 0;
}

void Mensaje( int pid, int ppid){
    printf("Soy el proceso Ejercicio1 con PID %d, mi padre es %d\n", pid, ppid);
}