#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <dirent.h>
#include <ctype.h>

#define MAX_FILES 100

// Datos que manejaran los hilos
struct ThreadData {
    char *directory;
    char *output_file;
    char *files[MAX_FILES];
    int file_count;
    pthread_mutex_t lock;
    int total_counts[10];
};

// Funcion auxiliar para validar -t
int es_entero_positivo(const char *str) {
    if (str == NULL || *str == '\0') {
        return 0;
    }
    for (int i = 0; str[i] != '\0'; i++) {
        if (!isdigit(str[i])) {
            return 0;
        }
    }
    return 1;
}

// Funcion que cada hilo ejecuta
void *contar_numeros(void *arg) {
    struct ThreadData *data = (struct ThreadData *)arg;

    while (1) {
        pthread_mutex_lock(&data->lock);
        if (data->file_count == 0) {
            pthread_mutex_unlock(&data->lock);
            break;
        }
        char *file = data->files[--data->file_count];
        pthread_mutex_unlock(&data->lock);

        FILE *fp = fopen(file, "r");
        if (fp != NULL) {
            int counts[10] = {0}; // Contador de números del 0 al 9

            int c;
            while ((c = fgetc(fp)) != EOF) {
                if (isdigit(c)) {
                    counts[c - '0']++;
                }
            }

            printf("Thread %ld: Archivo leído %s. Apariciones 0=%d, 1=%d, 2=%d, 3=%d, 4=%d, 5=%d, 6=%d, 7=%d, 8=%d, 9=%d\n",
                   pthread_self(), file, counts[0], counts[1], counts[2], counts[3], counts[4], counts[5], counts[6], counts[7], counts[8], counts[9]);

            fclose(fp);

            pthread_mutex_lock(&data->lock);
            for (int i = 0; i < 10; i++) {
                data->total_counts[i] += counts[i];
            }
            pthread_mutex_unlock(&data->lock);
        } else {
            perror("Error al abrir el archivo");
        }
    }

    pthread_exit(NULL);
}

int main(int argc, char *argv[]) {
    if (argc < 5) {
        printf("Argumentos insuficientes, uso: %s -t <nro> -i <directorio> [-o <archivo>]\n", argv[0]);
        return EXIT_FAILURE;
    }

    int num_threads;
    char *directory = NULL;
    char *output_file = NULL;
    int threads_provided = 0;

    // Parseo de parametros
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-t") == 0 && i + 1 < argc) {
			if(!es_entero_positivo(argv[i+1])){
                printf("El valor proporcionado para -t debe ser un número entero positivo.\n");
                return EXIT_FAILURE;
            }
            num_threads = atoi(argv[i + 1]);
            threads_provided = 1;
            i++;
        } else if ((strcmp(argv[i], "-i") == 0 || strcmp(argv[i], "--input") == 0) && i + 1 < argc) {
            directory = argv[i + 1];
            i++;
        } else if ((strcmp(argv[i], "-o") == 0 || strcmp(argv[i], "--output") == 0) && i + 1 < argc) {
            output_file = argv[i + 1];
            i++;
        }
		else{
			printf("Argumento no valido, uso: %s -t <nro> -i <directorio> [-o <archivo>]\n",argv[0]);
			return EXIT_FAILURE;
		}
    }

    if (directory == NULL) {
        printf("Debe proporcionar el directorio de entrada.\n");
        return EXIT_FAILURE;
    }

    if (!threads_provided) {
        printf("Debe proporcionar la cantidad de hilos a través de la opción -t.\n");
        return EXIT_FAILURE;
    }

    struct ThreadData data = { directory, output_file, {0}, 0, PTHREAD_MUTEX_INITIALIZER, {0} };

    DIR *dir;
    struct dirent *entry;

    if ((dir = opendir(directory)) == NULL) {
        perror("Error al abrir el directorio");
        return EXIT_FAILURE;
    }

    // Guardar nombres de los archivos del directorio en las estructuras de los hilos
    while ((entry = readdir(dir)) != NULL && data.file_count < MAX_FILES) {
        if (entry->d_type == DT_REG && strstr(entry->d_name, ".txt") != NULL) {
            char *filepath = malloc(strlen(directory) + strlen(entry->d_name) + 2);
            sprintf(filepath, "%s/%s", directory, entry->d_name);
            data.files[data.file_count++] = filepath;
        }
    }
    closedir(dir);

    pthread_t threads[num_threads];

    // Crear y ejecutar threads
    for (int i = 0; i < num_threads; i++) {
        if (pthread_create(&threads[i], NULL, contar_numeros, (void *)&data) != 0) {
            perror("Error al crear el thread");
            return EXIT_FAILURE;
        }
    }

    // Esperar a que todos los threads finalicen
    for (int i = 0; i < num_threads; i++) {
        pthread_join(threads[i], NULL);
    }

    // Liberar la memoria utilizada para almacenar los nombres de los archivos
    for (int i = 0; i < data.file_count; i++) {
        free(data.files[i]);
    }

    // Imprimir el total de apariciones
    printf("Finalizado lectura. Apariciones total: 0=%d, 1=%d, 2=%d, 3=%d, 4=%d, 5=%d, 6=%d, 7=%d, 8=%d, 9=%d\n",
           data.total_counts[0], data.total_counts[1], data.total_counts[2], data.total_counts[3], data.total_counts[4],
           data.total_counts[5], data.total_counts[6], data.total_counts[7], data.total_counts[8], data.total_counts[9]);

	// Escribir el resultado en el archivo de salida si se especificó
    if (output_file != NULL) {
        FILE *output_fp = fopen(output_file, "w");
        if (output_fp != NULL) {
            fprintf(output_fp, "Finalizado lectura. Apariciones total: 0=%d, 1=%d, 2=%d, 3=%d, 4=%d, 5=%d, 6=%d, 7=%d, 8=%d, 9=%d\n",
                    data.total_counts[0], data.total_counts[1], data.total_counts[2], data.total_counts[3], data.total_counts[4],
                    data.total_counts[5], data.total_counts[6], data.total_counts[7], data.total_counts[8], data.total_counts[9]);
            fclose(output_fp);
        } else {
            perror("Error al abrir el archivo de salida");
        }
    }

    return EXIT_SUCCESS;
}
