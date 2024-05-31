#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include <dirent.h>
#include <string.h>
#include <math.h>
#include "../Bibliotecas/headers/parsearParametros.h"
typedef struct{
    int apariciones[10];
} salidaThread;

typedef struct
{
    char** nombresArchivo;
    int cantArchivos;
    int numeroDeThread;
    salidaThread* salidaAcumulada;
    pthread_mutex_t* mutex;
} parametroThread;
void mostrarAyuda(){
    puts("Mostrando ayuda muy desarrollada");
    puts("-t/--threads");
    puts("-i/--input");
    puts("-o/--output");
    puts("-h/--help");
}
int verificarExtension(const char *s, const char *ext) {
    int len_s = strlen(s);
    int len_ext = strlen(ext);

    if (len_ext > len_s) {
        return 0;
    }

    const char *end_s = s + len_s - 1;
    const char *end_ext = ext + len_ext - 1;

    while (len_ext--) {
        if (*end_s-- != *end_ext--) {
            return 0;
        }
    }

    return 1;
}
int leerArchivos(char *directorio, char ***archivos){
    DIR* dir;
    struct dirent *ent;
    int conteo = 0;

    dir = opendir(directorio);
    if (dir == NULL) {
        perror("Error al abrir el directorio");
        return -1;
    }
    while ((ent = readdir(dir)) != NULL) {//veo cuantos archivos txt hay
        // Verificar si el nombre del archivo tiene la extensión deseada
        if (verificarExtension(ent->d_name, ".txt") == 1) {
            conteo++;
        }
    }
    closedir(dir);
    
    *archivos = malloc(conteo * sizeof(char*)); 
    if(*archivos == NULL){
        puts("Error asignando memoria en archivos");
        return -1;
    }
    dir = opendir(directorio);
    if (dir == NULL) {
        perror("Error al abrir el directorio");
        return -1;
    }
    int i = 0;
    while ((ent = readdir(dir)) != NULL) {//veo cuantos archivos txt hay
        char nombreEntero[255];
        strcpy(nombreEntero, directorio);
        // Verificar si el nombre del archivo tiene la extensión deseada
        
        if (verificarExtension(ent->d_name, ".txt") == 1) {
            
            strcat(nombreEntero, ent->d_name);
            (*archivos)[i] = malloc(strlen(nombreEntero)+1);
            if((*archivos)[i] == NULL){
                puts("Error asignando memoria en archivos");
            }
            strcpy((*archivos)[i], nombreEntero);
            i++;
        }
    }
    closedir(dir);
    return conteo;
}
void ImprimirConteo(salidaThread* conteos){
    for(int i=0;i<9;i++){
        printf("%d = %d, ", i, conteos->apariciones[i]);
    }
    printf("%d = %d\n", 9, conteos->apariciones[9]);
}
void* procesarArchivo(void* arg){
    pthread_mutex_t* mutex = ((parametroThread*)arg)->mutex;
    for(int j = 0;j<((parametroThread*)arg)->cantArchivos;j++){
        //printf("Leyendo %s\n", ((parametroThread*)arg)->nombresArchivo[j]);
        FILE* arch = fopen(((parametroThread*)arg)->nombresArchivo[j], "r");
        salidaThread salida;
        for (int i = 0; i < 10; i++) { // inicializo en 0 el array
            salida.apariciones[i] = 0;
        }
        if (arch == NULL){
            printf("No se pudo abrir el archivo --%s--\n", ((parametroThread*)arg)->nombresArchivo[j]);
            pthread_exit(NULL);
        }
        char caracterLeido = fgetc(arch);
        while(caracterLeido != EOF){
            //printf("%c", caracterLeido);
            if(caracterLeido < '0' || caracterLeido > '9'){
                caracterLeido = fgetc(arch);
                continue;
            }
            ++salida.apariciones[caracterLeido-48]; //en la posicion 0 esta el conteo del caracter 0 y asi...

            caracterLeido = fgetc(arch);
        }
        //printf("----%d\n", salida.apariciones[0]);
        pthread_mutex_lock(mutex);
        printf("Thread %d: Archivo leido '%s'. Apariciones ",((parametroThread*)arg)->numeroDeThread,((parametroThread*)arg)->nombresArchivo[j]);
        ImprimirConteo(&salida);
        for(int i = 0;i<10;i++){ //TODO sincronizar, mutex
            (((parametroThread*)arg)->salidaAcumulada)->apariciones[i] += salida.apariciones[i]; // copio el array local al array que existe fuera del thread
        }
        pthread_mutex_unlock(mutex);
        fclose(arch);
    }
    
    pthread_exit(NULL);
}
void repartirArchivos(char ** archivos,int cantArchivos, parametroThread *parametros, int paralelismo){
    if(paralelismo<cantArchivos){
        int archivosContados = 0,archivosFaltantes,hilosRestante,archivosALeer;
        for (int i = 0;i<paralelismo;i++){
            archivosFaltantes = cantArchivos - archivosContados;
            hilosRestante = paralelismo-i;
            archivosALeer = (int)ceil(archivosFaltantes/(float)hilosRestante);
            archivosContados += archivosALeer;
            parametros[i].cantArchivos = archivosALeer;
            parametros[i].nombresArchivo = malloc(archivosALeer * sizeof(char*));
            //printf("%d\n", parametros[i].cantArchivos);
        }
    }else{
        for (int i = 0;i<cantArchivos;i++){
            parametros[i].cantArchivos = 1;
            parametros[i].nombresArchivo = malloc(sizeof(char*));
        }
    }
    int nParametro = 0;
    
    int nArchivo = 0;
    for (int i = 0; i < cantArchivos; i++)
    {
        parametros[nParametro].nombresArchivo[nArchivo] = malloc(strlen(archivos[i])+1);
        strcpy(parametros[nParametro].nombresArchivo[nArchivo], archivos[i]);
        nArchivo++;
        if(nArchivo==parametros[nParametro].cantArchivos){
            nParametro++;
            nArchivo = 0;
        }
    }
    
}
int validarParametros(char *directorio ,char *threads ){
    if(directorio == NULL){
        printf("El directorio de entrada es requerido (-i/--input)\n");
        return 0;
    }
    if(threads == NULL){
        printf("La cantidad de threads es requerido (-t/--threads)\n");
        return 0;
    }
    if(atoi(threads)<= 0){
        printf("La cantidad de threads tiene que ser mayor a 0\n");
        return 0;
    }
}
int main(int argc, char* argv[]){
    char *directorio = NULL, *salida = NULL, *threads = NULL, *help = NULL;
    char * opcionesLargas[] = {"threads","input","output","help"};
    char ** variables [] = {&threads, &directorio, &salida, &help};
    char ** archivos = NULL;
    parsearParametros(argv,argc, "t:i:o:h", opcionesLargas, 4, variables);
    if (argc == 1 || help != NULL){ // el nombre del programa tambien cuenta como parametro y esta siempre
        mostrarAyuda();
        freeParametros(4,variables);
        return 0;
    }
    if(!validarParametros(directorio,threads)){
        freeParametros(4,variables);
        return 1;
    }
    if(salida != NULL){
        FILE* file = fopen(salida, "w");
        if (file == NULL) {
            perror("Error al abrir el archivo en modo 'write'");
            freeParametros(4,variables);
            return 1;
        }
        //borro todo el contenido previo del archivo si existia, y sino solo lo crea
        fclose(file);

        freopen(salida, "a", stdout); //redirige toda la salida estandar al archivo
        if (file == NULL) {
            perror("Error al abrir el archivo en modo 'append'");
            freeParametros(4,variables);
            return 1;
        }
    }

    pthread_mutex_t mutex;
    pthread_mutex_init(&mutex,NULL);
    int cantArchivos = leerArchivos(directorio, &archivos); //devuelve la cantidad de archivos y deja en archivos los nombres de los archivos

    int cantThreads = atoi(threads) < cantArchivos ? atoi(threads) : cantArchivos; //para que no genere threads de mas
    parametroThread* parametros = malloc (cantThreads * sizeof(parametroThread)); //TODO validar que se asigno memoria
    
    pthread_t *tids = malloc (cantThreads * sizeof(pthread_t)); //TODO validar que se asigno memoria
    salidaThread salidaAcumulador = {{0}}; //setea en 0 todos los contadores
    repartirArchivos(archivos, cantArchivos,parametros, cantThreads);

    for(int i = 0;i< cantThreads;i++){
        //printf("%d\n", parametros[i]->cantArchivos );
        parametros[i].mutex = &mutex;
        parametros[i].numeroDeThread = i+1;
        parametros[i].salidaAcumulada = &salidaAcumulador;
        pthread_create(&tids[i], NULL, procesarArchivo, &parametros[i]);
    }
    
    for(int i = 0;i< cantThreads;i++){
        pthread_join(tids[i], NULL);
    }

    printf("Finalizado lectura: Apariciones total:  ");
    ImprimirConteo(&salidaAcumulador);
    for(int i = 0;i<cantThreads;i++){
        for (int j = 0; j < parametros[i].cantArchivos; j++)
        {
            free(parametros[i].nombresArchivo[j]);
        }
        free(parametros[i].nombresArchivo);
    }
    for(int i = 0;i<cantArchivos;i++){
        free(archivos[i]);
    }
    fclose(stdout);
    free(archivos);
    pthread_mutex_destroy(&mutex);
    free(tids);
    free(parametros);
    freeParametros(4,variables);
    return 0;
}