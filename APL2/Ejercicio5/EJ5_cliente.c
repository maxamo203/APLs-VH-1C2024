#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include "../Bibliotecas/headers/tablero.h"
#include <errno.h>
#include <termios.h>

int main(int argc, char* argv[]){
    char nombre[30];
    strcpy(nombre, argv[1]);
    struct sockaddr_in socketConfig;
    Tablero tablero;
    int opt = 1;
    socketConfig.sin_family = AF_INET;
    socketConfig.sin_port = htons(8080);
    inet_pton(AF_INET, "127.0.0.1", &socketConfig.sin_addr);

    int socketComunicacion = socket(AF_INET, SOCK_STREAM, 0);
    // Habilitar SO_KEEPALIVE
    
    int resultadoConexion = connect(socketComunicacion,
        (struct sockaddr *)&socketConfig, sizeof(socketConfig));

    if (resultadoConexion < 0)
    {
        puts("Error en la conexión");
        return EXIT_FAILURE;
    }

    char buffer[2000];
    int bytesRecibidos = 0;
    int entrada[2];
    char bytesEscritos[10];
    puts("Esperando partida...");
    while ((bytesRecibidos = read(socketComunicacion, buffer, sizeof(buffer) - 1))>0)
    {   
        if(strcmp(buffer, "TU TURNO") == 0){
            printf("Tu tunro wachin\n");
            tcflush(STDIN_FILENO, TCIFLUSH);
            while(scanf("%d %d", &entrada[0],&entrada[1]) != 2){
                puts("Entrada invalida");
                int c;
                while ((c = getchar()) != '\n' && c != EOF);
            }
            memcpy(bytesEscritos, entrada,sizeof(entrada));
            write(socketComunicacion,bytesEscritos, sizeof(bytesEscritos));
        }else if(bytesRecibidos == 128){//el tamaño del buffer que envia, es el tablero
            memcpy(&tablero,buffer, sizeof(tablero));
            imprimirTablero(&tablero);
        }
        else{
            printf("%s\n", buffer);
            if(strcmp(buffer, "JUEGO INICIADO") == 0){
                write(socketComunicacion, nombre, sizeof(nombre)); //manda su nombre
            }
        }
        //printf("cant bytes [%d] [%s]\n", bytesRecibidos, buffer);
        //buffer[bytesRecibidos] = 0;
        
       
        //TODO: limpiar buffer por entradas anteriores
        
    }
    printf("%d %d\n", errno, bytesRecibidos);
    if(bytesRecibidos == -1){
        puts("Servidor Caido");
    }
    close(socketComunicacion);

    return EXIT_SUCCESS;
}