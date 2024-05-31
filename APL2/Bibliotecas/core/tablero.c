#include "../headers/tablero.h"

void imprimirTablero(Tablero* tab){
    printf("\033[2J");//borrar pantalla
    printf("\033[H"); //mover arriba
    printf("  0 1 2 3\n");
    printf(" ┌───────┐\n");
    for(int i = 0;i<4;i++){
        printf("%d│", i);
        for(int j = 0;j<4;j++){
            if(tab->descubiertos[i][j] != 0){
                if(i == tab->yAnt2 && j == tab->xAnt2){
                    if(tab->xAnt == -1){
                        printf("\033[1;33m%c\033[0m", tab->tablero[i][j]);
                     //puts("AMARILLO");
                    }else{
                        printf("\033[1;31m%c\033[0m", tab->tablero[i][j]);
                    //puts("ROJO");
                    }
                }
                else if(i == tab->yAnt && j == tab->xAnt){
                    printf("\033[1;31m%c\033[0m", tab->tablero[i][j]);
                    //puts("ROJO");
                }else{
                    printf("\x1b[32m\x1b[1m%c\x1b[0m", tab->tablero[i][j]);
                    //puts("VERDE");
                }

            }else{
                printf("%s", "░");
            }
            if(j<3){
                printf("│");
            }
        }
            puts("│");
            if(i<3)
                puts(" ├─┼─┼─┼─┤");
    }
    printf(" └───────┘\n");
}

void generarTablero(Tablero* tab){
    tab->xAnt=-1;
    tab->yAnt=-1;
    tab->xAnt2=-1;
    tab->yAnt2=-1;
    tab->ultimaOperacion = -1;
    srand(time(NULL));
    char inicio = 'A', fin = 'Z';
    int salto = 2;
    char letraRandomInicial = rand() % (fin-inicio + 1) + inicio;
    char letras[16];
    
    for(int i = 0;i<16;i+=2){
        letras[i] = letraRandomInicial;
        letras[i+1] = letraRandomInicial;
        letraRandomInicial = ((letraRandomInicial + salto)%(fin-inicio))+inicio;
    }
    for (int i = 16 - 1; i > 0; i--) {
        // Generar un índice aleatorio entre 0 y i (inclusive)
        int j = rand() % (i + 1);
        // Intercambiar el elemento en la posición i con el elemento en la posición j
        int temp = letras[i];
        letras[i] = letras[j];
        letras[j] = temp;
    }
    int indice = 0;
    for(int i = 0; i<4;i++){
        for (int j = 0;j<4;j++){
            tab->tablero[i][j] = letras[indice];
            tab->descubiertos[i][j] = 0;
            indice++;
        }
    }
}
int darVueltaPosicion(Tablero* tab, int x, int y) {
    x = x % 4;
    y = y % 4;
    
    printf("Antes: %d %d %d %d\n", tab->xAnt, tab->yAnt, tab->xAnt2, tab->yAnt2);
    
    
   // Intento de destapar algo que ya estaba destapado
    if (tab->descubiertos[y][x] == 1) { 
        // tab->xAnt2 = -1;
        // tab->yAnt2 = -1;
        if(tab->xAnt2 != -1 && tab->xAnt == -1 || (x != tab->xAnt2 && y != tab->yAnt2 && x != tab->xAnt && y != tab->yAnt)){
            printf("Después1: %d %d %d %d\n", tab->xAnt, tab->yAnt, tab->xAnt2, tab->yAnt2);
            return 0;
        }
        else{//quiere dar vuelta una de las errnoeas de vuelta
            tab->descubiertos[tab->yAnt][tab->xAnt] = 0;
            tab->descubiertos[tab->yAnt2][tab->xAnt2] = 0;
            tab->xAnt = -1;
            tab->yAnt = -1;
            tab->xAnt2 = -1;
            tab->yAnt2 = -1;
        }
    }
    if((tab->xAnt2 != -1 && tab->xAnt != -1) || tab->xAnt2 == -1){ //primer destapada
        if (tab->xAnt != -1) { 
            // Hubo un error antes, reseteamos las posiciones anteriores
            tab->descubiertos[tab->yAnt][tab->xAnt] = 0;
            tab->descubiertos[tab->yAnt2][tab->xAnt2] = 0;
            tab->xAnt = -1;
            tab->yAnt = -1;
            tab->xAnt2 = -1;
            tab->yAnt2 = -1;
        }
        
        tab->descubiertos[y][x] = 1;
        tab->xAnt2 = x;
        tab->yAnt2 = y;
        printf("Después: %d %d %d %d\n", tab->xAnt, tab->yAnt, tab->xAnt2, tab->yAnt2);
        return 1;
    }else{ //hubo una destapada anterior
        if (tab->tablero[y][x] == tab->tablero[tab->yAnt2][tab->xAnt2]) { 
            // Destapa otra posición y acierta
            tab->descubiertos[y][x] = 1;
            tab->xAnt2 = -1;
            tab->yAnt2 = -1;
            printf("Después3: %d %d %d %d\n", tab->xAnt, tab->yAnt, tab->xAnt2, tab->yAnt2);
            return 2;
        } else { 
            // Destapa otra posición y no coinciden
            tab->descubiertos[y][x] = 1;
            tab->xAnt = x;
            tab->yAnt = y;
            printf("Después4: %d %d %d %d\n", tab->xAnt, tab->yAnt, tab->xAnt2, tab->yAnt2);
            return 3;
        }
    }
}
void escribirEnMemoria(Tablero* tab, void* shdm){
    for(int i = 0;i<4;i++){
        for (int j = 0; j < 4; j++)
        {
            ((Tablero*)shdm)->tablero[i][j] = tab->tablero[i][j];
            ((Tablero*)shdm)->descubiertos[i][j] = tab->descubiertos[i][j];
        }     
    }
    ((Tablero*)shdm)->tinicio = tab->tinicio;
    ((Tablero*)shdm)->tfin = tab->tfin;
    ((Tablero*)shdm)->ultimaOperacion = tab->ultimaOperacion;
    ((Tablero*)shdm)->xAnt = tab->xAnt;
    ((Tablero*)shdm)->xAnt2 = tab->xAnt2;
    ((Tablero*)shdm)->yAnt = tab->yAnt;
    ((Tablero*)shdm)->yAnt2 = tab->yAnt2;
}
void iniciarJuego(Tablero* tab){
    tab->tinicio = time(NULL);
}
void finalizarJuego(Tablero* tab){
    tab->tfin = time(NULL);
}
int tableroCompleto(Tablero* tab){
    for(int i = 0;i<4;i++){
        for (int j = 0; j < 4; j++)
        {
            if(tab->descubiertos[i][j] == 0)
                return 0;
        }     
    }
    return 1;
}