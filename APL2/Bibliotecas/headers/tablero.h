#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

typedef struct{
    char tablero[4][4];
    char descubiertos[4][4];
    double tinicio;
    double tfin;
    int xAnt;
    int yAnt;
    int xAnt2;
    int yAnt2;
    int ultimaOperacion;
} Tablero;
void imprimirTablero(Tablero* tab);
void generarTablero(Tablero* tab);
void iniciarJuego(Tablero* tab);
void finalizarJuego(Tablero* tab);
int darVueltaPosicion(Tablero* tab, int x, int y);
void escribirEnMemoria(Tablero* tab, void* shdm);
int tableroCompleto(Tablero* tab);