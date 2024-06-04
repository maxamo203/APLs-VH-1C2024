#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include "../Bibliotecas/headers/tablero.h"
#include "../Bibliotecas/headers/parsearParametros.h"
#include <errno.h>
#include <termios.h>

#define MAX_NAME_LENGTH 30
void mostrarAyuda()
{
    puts("Mostrando AYUDA");
    puts("-n/--nickname --> Indica el nombre con el que va a jugar el usuario");
    puts("-p/--puerto --> Indica el puerto donde esta escuchando el servidor");
    puts("-s/--servidor --> Indica la direccion (IP) del servidor");
}
int startsWith(const char* src, const char* obj){
    while(*src != 0 && *obj != 0){
        if(*src++ != *obj++){
            return 0;
        }
    }
    return *obj == 0;
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
int validarParametros(char* nombre, char* puerto, char* servidor){
    if(nombre == NULL || puerto == NULL || servidor == NULL){
        puts("ERROR: El nickname, puerto e ip del servidor son requeridos");
        return 0;
    }
    if(!(isNumber(puerto) && atoi(puerto)>=1024)){
        puts("ERROR: El puerto debe ser un numero mayor a 1024");
        return 0;
    }
    if(strlen(nombre) > MAX_NAME_LENGTH){
        printf("ERROR: El nombre no puede tener mas de %d caracteres\n", MAX_NAME_LENGTH);
        return 0;
    }
}
int main(int argc, char* argv[]){
    char *nombre = NULL, *puerto = NULL,*servidor, *help = NULL;
    char *opcionesLargas[] = {"nickname","puerto","servidor", "help"};
    char **variables[] = {&nombre, &puerto, &servidor, &help};
    parsearParametros(argv, argc, "n:p:s:h", opcionesLargas, 4, variables);
    if(help){
        mostrarAyuda();
        freeParametros(4, variables);
        return 0;
    }
    if(validarParametros(nombre, puerto, servidor) == 0){
        freeParametros(4, variables);
        return 1;
    }
    struct sockaddr_in socketConfig;
    Tablero tablero;
    int opt = 1;
    socketConfig.sin_family = AF_INET;
    socketConfig.sin_port = htons(atoi(puerto));
    inet_pton(AF_INET, servidor, &socketConfig.sin_addr);

    int socketComunicacion = socket(AF_INET, SOCK_STREAM, 0);
    // Habilitar SO_KEEPALIVE
    
    int resultadoConexion = connect(socketComunicacion,
        (struct sockaddr *)&socketConfig, sizeof(socketConfig));

    if (resultadoConexion < 0)
    {
        puts("Error en la conexión");
        close(socketComunicacion);
        return EXIT_FAILURE;
    }

    char buffer[2000];
    int bytesRecibidos = 0;
    int entrada[2];
    char bytesEscritos[10];
    char termino = 0;
    puts("Esperando partida...");
    while ((bytesRecibidos = read(socketComunicacion, buffer, sizeof(buffer) - 1))>0)
    {   
        if(strcmp(buffer, "TU TURNO") == 0){
            printf("Ingresa la posicion (x y): ");
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
                write(socketComunicacion, nombre, MAX_NAME_LENGTH); //manda su nombre
            }
            else if(startsWith(buffer, "RESULTADOS:")){
                termino = 1;
            }
        }
    }
    //printf("%d %d\n", errno, bytesRecibidos);
    if(!termino){
        puts("Servidor Caido");
    }
    close(socketComunicacion);

    return EXIT_SUCCESS;
}