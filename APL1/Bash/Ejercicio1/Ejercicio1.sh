#! /bin/bash
#INTEGRANTES:
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÃ±AKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
function mostrarAyuda(){
echo 'Modo de uso:
-d|--direccion <path> * --> Indica la direccion de la carpeta (relativa o absoluta) donde estan los archivos a analizar
-s|--salida <path> ** --> Indica la ruta del archivo (relativa o absoluta) donde se escribirá el resultado del procesamiento
-p|--pantalla --> Indica si la salida se imprimira por consola
-h|--help --> Muestra la ayuda y omite el resto de parametros

-s y -p no pueden usarse a la vez
* : OBLIGATORIO
**: Si no se indica ni -s ni -p se generara por defecto el archivo de salida en ./resultado.json'
}
function generarJSON(){
    #echo $1 "JIJi"
    IFS_VIEJO="$IFS"
    IFS=$'\n' #el simbolo $ acá es para que bash interprete el \n como salto de linea, y no como la cadena literal "\n"
    #lo que hace la linea anterior es cambiar el separador de parametros de bash, por defecto toma espacios, \n y \r (creo) para separar
    #entonces lo fuerzo a que use solo el \n, para que diferencie los disntinto archivos aunque tengan espacios
    
    
    if [ ! -d "$1" ]; then #si no existe el directorio tira error
        echo Ubicacion no encontrada, saliendo
        exit 1
    fi
    
    archivos=`find "$1" -maxdepth 1 -type f -iname "*.csv"` #iname, busqueda insensible

    for archivo in $(find "$1" -type f ! -iname "*.csv"); do
        echo -e "\033[0;33m$archivo no tiene extensión csv, omitiendo\033[0m" #pinta de amarillo, y lo vuelve a blanco
    done  
    if [ -z $archivos ]; then
        echo "Directorio vacio, saliendo"
        exit 0
    fi
    awk -F',' '
$1 ~ /[0-9]+/ { 
    ponderacion = 10/(NF-1)
    nota = 0
    for( i=2;i<=NF; i++){
        if($i == "b")
            nota += ponderacion
        if($i == "r")
            nota += (ponderacion/2)    
    }


    n = split(FILENAME, path, "/")
    split(path[n], name, ".")
    alumnos[$1] = alumnos[$1] "   {\"materia\":" name[1] ", \"nota\":" int(nota) "},\n"
}
END {
    print "{\"notas\": ["
    for (i in alumnos){
        print " {"
        print "  \"dni\": \""i"\","
        print "  \"notas\": ["
        alumnoLimpio = substr(alumnos[i],1,length(alumnos[i])-2)
        print  alumnoLimpio
        contador++
        if(contador == length(alumnos))
            print "  ]}"
        else
            print "  ]},"
    }

    print "] }"
}' $archivos > $2
IFS="$IFS_VIEJO"
}

function validarParametros(){
    if [[ "$directorio" =~ ^-p || "$salida" =~ ^-p ]]; then #si empiezan con -p (un error, por ej, si hizo -d -p, en directorio va a quedar -p)
        echo "Opcion invalida, saliendo" >&2
        exit 1
    fi
    if [[ "$salida" != "" && "$pantalla" == true ]]; then #pasa los dos parametros, mal
        echo "Solo puede haber una opcion, -s o -p" >&2
        exit 2
    fi
    if [ "$directorio" == "" ]; then #no pasa direccion de origen
        echo "No indico origen (-d/--direccion)" >&2
        exit 3
    fi
    if [ "$pantalla" == "true" ]; then
        salida=/dev/stdout
    else
        if [ "$salida" == "" ];then #si no especifica ni -p ni -s
            salida="./resultado.json" #salida por defecto
        fi
    fi

    return 0
}
# dir="../../NotasEjercicio1"
# salida="/dev/stdout"


opcionesCortas=d:s:ph
opcionesLargas=directorio:,salida:,pantalla,help

opts=`getopt -o $opcionesCortas -l $opcionesLargas -- "$@" 2> /dev/null`
if [ "$?" != "0" ]; then
    echo "Error parseando opciones, saliendo" >&2;
    exit 4;
fi

eval set -- $opts #no se que hace
#echo $1 $2

while true; do
    
    case "$1" in
    -d|--directorio )
        directorio="$2" 
        shift 2
        ;;
    -s|--salida )
        salida="$2"
        shift 2
        ;;
    -p|--pantalla )
        pantalla=true
        shift
        ;;
    -h|--help )
        help=true
        shift
        ;;
    --)
        shift
        break
        ;;
    * )
        echo "Opcion no contemplada: ($1)" >&2
        exit
    esac
done

if [ "$help" == "true" ]; then
    mostrarAyuda
    exit 0
fi
validarParametros #verifica si son parametros validos y establece la salida segun sea necesario (archivo o stdout)



generarJSON "$directorio" "$salida"

#echo "Fin"
