#include "parsearParametros.h"
#include <stdarg.h>
#include <getopt.h>
#include <string.h>
#include <regex.h>
#include <stdlib.h>
#include <stdio.h>
void parsearParametros(char** parametros,int argc, char* opcionesCortas, char** opcionesLargas, int cant, char *** variables){
    
    struct option *Parametros = malloc(sizeof(struct option) * (cant+1));
    int lectorCortas = 0;
    int opt;
    
    for(int i = 0;i<cant;i++){
        int hasArg = 0;
        Parametros[i].val = opcionesCortas[lectorCortas]; // la opcion corta de la opcion larga
        if (opcionesCortas[lectorCortas+1] == ':'){
            hasArg = 1;
            lectorCortas += 2;
        }else{
            lectorCortas++;
        }
        
        Parametros[i].name = opcionesLargas[i]; //creo que no hace falta strcpy aca, xq opcioens larga va a ser siempre la misma
        Parametros[i].has_arg = hasArg;
        Parametros[i].flag = NULL;
    }
    
    Parametros[cant].name = NULL; Parametros[cant].has_arg = 0; Parametros[cant].flag = NULL; Parametros[cant].val = 0;
    while ((opt = getopt_long(argc, parametros, opcionesCortas, Parametros,NULL)) != -1){
        // if (opt == '?'){
        //     puts("No se le paso un argumento al parametro");
        //     continue;
        // }
        int lector = 0; //escanea toda opcionesCortas (incluso :)
        int posArg = 0; //dice la posicion de la letra
        int encontro = 0;
        int hasArg = 0;
        while(opcionesCortas[lector] != 0){
            if(opcionesCortas[lector] != opt){
                
                if (opcionesCortas[lector] != ':'){
                    posArg++;
                }
                lector++;
                continue;
            }
            encontro = 1;
            if(opcionesCortas[lector+1] == ':'){
                hasArg = 1;
            }
            break;
        }
        if(!encontro){
            puts("Parametro no reconocido");
            continue;
        }
        if(hasArg){
            regex_t regex;
            regcomp(&regex, "(-\\w)|(--\\w+)",REG_EXTENDED);
            regmatch_t match;
            if(regexec(&regex, optarg,1,&match,0) == 0){
                printf("Argumento no valido %s\n", optarg);
                continue;
            }
            //printf("%s %dsexo\n", optarg, posArg);
            *(variables[posArg]) = malloc(strlen(optarg) + 1); // +1 para el carácter nulo
            strcpy(*(variables[posArg]), optarg);
        }else{
            *(variables[posArg]) = malloc(2); // Dos caracteres: "1" + carácter nulo
            strcpy(*(variables[posArg]), "1");
            //printf("%s %dsexont\n", optarg, posArg);
            //printf("%s %dsexont\n", optarg, posArg);
        }
    }
    free(Parametros);
    //printf("%s\n", variables[1]);
}
void freeParametros(int cant, char *** variables){
    for(int i = 0;i<cant;i++){
        free(*(variables[i]));
    }
}
