#! /bin/bash
function mostrarAyuda(){
    echo 'Modo de uso:
-d|--directorio <path> ** --> Indica el directorio donded estan los archivos a analizar
-x|--extension <extension> * --> Indica la extension de los archivos a analizar, si no se pasa analiza todos los archivos del directorio sin importar la extension. Ej: txt | dat
-s|--separador <separador> * --> Indica la secuencia de caracteres que haran de separador de palabras, por defecto es ESPACIO
-o|--omitir <omitir> * --> Indica las subcadenas, separadas por comas, que debera contener una palabra para no ser tomada en cuenta. Ej: "ar,er,oca,"
-c|--case * --> Indica si distinguira mayusculas de minusculas, por defecto no diferencia entre mayusculas y minusculas
-h|--help --> Muestra la ayuda y termina el programa
**:OBLIGATORIO
*:OPCIONAL'
}

CORTAS=d:x:s:o:ch
LARGAS=directorio:,extension:,separador:,omitir:,case,help

opts=`getopt -o $CORTAS -l $LARGAS -- "$@" 2> /dev/null`
if [ "$?" != "0" ]; then
    echo "Error parseando opciones, saliendo" >&2;
    exit 1;
fi

extension=".*" #en regex, acepta cualquier caracter las veces que sea
separador=" "
omitir=""
caseSensitive="false"
eval set -- $opts #no se que hace
while true; do
    case "$1" in 
    -d|--directorio )
        dir="$2"
        shift 2
        ;;
    -x|--extension )
        extension="$2"
        shift 2
        ;;
    -s|--separador )
        separador="$2"
        shift 2
        ;;
    -o|--omitir )
        omitir="$2"
        shift 2
        ;;
    -c|--case )
        caseSensitive="true"
        shift
        ;;
    -h|--help )
        ayuda="true"
        shift
        ;;
    -- )
        shift
        break
        ;;
    * )
        echo "Opcion no contemplada: ($1)" >&2
        exit 1
    esac
done

if [ "$ayuda" == "true" ]; then
    mostrarAyuda
    exit 0
fi
if [ "$dir" == "" ]; then
    echo "Direccion no pasada, saliendo" >&2
    exit 2
fi
IFS_VIEJO="$IFS"
IFS=$'\n'
archivos=`ls -d "$dir"/*`

#pasar todo a minuscula (asi Linux y linux es la misma palabra)
#remover caracteres especiales (.,!? etc), salvo el delimitador 

awk -F"$separador" -v extension="$extension" -v omitir="$omitir" -v AceptaCase="$caseSensitive" '
BEGIN {
    archivoRegex = "\\." extension "$" #el simbolo $ al final de la regex indica que quiero que la cadena termine con lo que le dije antes
    
    #por ejemplo para la extension de un archivo seria tipo txt$, porque quiero quedarme con los archivos que terminen txt
    conteoArchivos = 0
    cantTotalPalabras = 0
    if (AceptaCase != "true")
        omitir = tolower(omitir)
        separador = tolower(separador)
    split(omitir, palabrasAOmitir, ",")
}
match(FILENAME, archivoRegex){
    if (archivoAnterior != FILENAME) #una especie de corte de control para contar los archivos que efectivamente se analizan (xq algunos pueden ser omitidos por la extension)
        conteoArchivos++

    if (AceptaCase != "true")
            $0 = tolower($0) #pasa todo a minuscula

    gsub(/[^A-Za-z0-9áéíóúÁÉÍÓÚ ]/,FS,$0) #elimina todo lo que no sea letra o numero o espacio (importante el espacio entre el 9 y el ]) y lo reemplaza por el separador

    for(i=1; i<=NF; i++){
        omitir = "false"
        for (j = 1;j<= length(palabrasAOmitir);j++)
            if (match($i, palabrasAOmitir[j])){ #Si la palabra actual contiene alguna de las subcadenas pasadas para omitir
                omitir = "true"
                break
            }
        if (omitir == "true"){
            print "Omitiendo: " $i
            continue
        }
        conteoLongitudPalabras[length($i)]++
        conteoDeOcurrenciasDePalabras[$i]++
        cantTotalPalabras++
        for ( j = 1; j<=length($i);j++ ){
            char = substr($i,j,1)
            conteoCaracteres[char]++
        }
    }
    archivoAnterior = FILENAME
}
END{
    #Muestra las distintas longitudes de palabras ordenadas
    maximaLongitudDePalabra = 0
    for (longitud in conteoLongitudPalabras){
        print "Palabras de " longitud " caracteres: " conteoLongitudPalabras[longitud]
            
    }
    

    maxOcurrenciaDePalabras = 0
    for (ocurrencia in conteoDeOcurrenciasDePalabras){ #obtengo el maximo de ocurrencias de una palabra
        if (conteoDeOcurrenciasDePalabras[ocurrencia]>maxOcurrenciaDePalabras)
            maxOcurrenciaDePalabras = conteoDeOcurrenciasDePalabras[ocurrencia]
    }
    for(ocurrencia in conteoDeOcurrenciasDePalabras){ #cargo array con las palabras con mas ocurrencias
        if (conteoDeOcurrenciasDePalabras[ocurrencia] == maxOcurrenciaDePalabras){
            conteoMaximoDePalabras[ocurrencia] = 1 #las claves del array asociativo son las palabras que mas aparecieron
        }
    }
    print ""
    print "Palabra/s que mas aparecio/eron, (" maxOcurrenciaDePalabras ") veces"
    for (i in conteoMaximoDePalabras){
        print i
    }
    print ""
    print "Cantidad total de palabras: " cantTotalPalabras
    print ""

    if (conteoArchivos > 0)
        print "Promedio de palabras por archivo: " cantTotalPalabras/conteoArchivos
    else
        print "Promedio de palabras por archivo: 0" 

    maxOcurrenciaDeCaracteres = 0
    for (ocurrencia in conteoCaracteres){ #obtengo el maximo de ocurrencias de un caracter
        if (conteoCaracteres[ocurrencia]>maxOcurrenciaDeCaracteres)
            maxOcurrenciaDeCaracteres = conteoCaracteres[ocurrencia]
    }
    for(ocurrencia in conteoCaracteres){ #cargo array con los caracteres con mas ocurrencias
        if (conteoCaracteres[ocurrencia] == maxOcurrenciaDeCaracteres){
            conteoMaximoDeCaracteres[ocurrencia] = 1 #las claves del array asociativo son los caracteres que mas aparecieron
        }
    }
    print ""
    print "Caracteres/s que mas aparecio/eron, (" maxOcurrenciaDeCaracteres ") veces"
    for (i in conteoMaximoDeCaracteres){
        print i
    }
    
}
' $archivos

IFS="$IFS_VIEJO"