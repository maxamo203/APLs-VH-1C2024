#! /bin/bash

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

    archivos=`ls -d $1/* 2>&1` 
    if [ $? != 0 ]; then
        echo Ubicacion no encontrada, saliendo
        exit 1
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
}

function validarParametros(){
    if [[ "$directorio" =~ ^-p || "$salida" =~ ^-p ]]; then #si empiezan con -p (un error) 
        echo "Opcion invalida, saliendo" >&2
        exit 1
    fi
    if [[ "$salida" != "" && "$pantalla" == true ]]; then #pasa los dos parametros, mal
        echo "Solo puede haber una opcion, -s o -p" >&2
        exit 1
    fi
    if [ "$directorio" == "" ]; then #no pasa direccion de origen
        echo "No indico origen (-d/--direccion)" >&2
        exit 1
    fi
    
    if [ "$pantalla" == "true" ]; then
        salida=/dev/stdout
        return 0
    fi
}
# dir="../../NotasEjercicio1"
# salida="/dev/stdout"


opcionesCortas=d:s:ph
opcionesLargas=directorio:,salida:,pantalla,help

opts=`getopt -o $opcionesCortas -l $opcionesLargas -- "$@" 2> /dev/null`
if [ "$?" != "0" ]; then
    echo "Error parseando opciones, saliendo" >&2;
    exit 1;
fi

eval set -- $opts #no se que hace
salida="./resultado.json" #salida por defecto
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


#echo $salida
generarJSON $directorio $salida

echo "Fin"