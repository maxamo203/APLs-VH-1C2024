void parsearParametros(char** parametros,int argc, char* opcionesCortas, char** opcionesLargas, int cant, char *** variables);
void freeParametros(int cant, char *** variables);

/*
char *directorio = NULL, *salida = NULL, *threads = NULL, *help = NULL;
char * opcionesLargas[] = {"threads","input","output","help"};
char ** variables [] = {&threads, &directorio, &salida, &help};
parsearParametros(argv,argc, "t:i:o:h", opcionesLargas, 4, variables);
printf("%s %s %s %s\n", directorio, salida, threads, help);
freeParametros(4,variables); //esta funcion es para liberar la memoria dinamica de las variables
*/