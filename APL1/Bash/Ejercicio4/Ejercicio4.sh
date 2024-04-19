#!/bin/bash

function mostrarAyuda(){
	echo "Todavía tengo que escribir la ayuda"
}

# Se encarga de validar que los parámetros pasados al script sean válidos
# Retornará un código de error en caso de que no lo sean
function validarParametros {
    # No se ingresó ningún directorio
    if [[ -z "$directorio" ]]; then
        echo "No se ingresó ningún directorio de origen (-d/--directorio)"
        exit 2
    fi
    # No se ingresó un directorio válido
    if [[ ! -d "$directorio" ]]; then
        echo "El directorio de origen ingresado NO es un directorio"
        exit 3
    fi
    # No se ingresó una salida válida
    if [[ -n "$salida" && ! -d "$salida" ]]; then
        echo "La salida ingresada NO es un directorio"
        exit 4
    fi
    # Para evitar recursión, el directorio de salida y el de origen no pueden ser el mismo
    if [[ "$directorio" == "$salida" ]]; then
        echo "El directorio de origen y de salida no pueden ser el mismo"
        exit 5
    fi
    # Es obligatorio especificar la salida o el parámetro kill
    if [[ -z "$salida" && -z "$kill" ]]; then
	echo "Se debe utilizar el comando -s/--salida o -k/--kill"
	exit 6
    fi
}

#Si ya hay una instancia del programa ejecutandose en un directorio, sale informando al usuario.
#En caso de que no haya otra instancia ejecutándose, se guardan los datos de esta instancia en /tmp
function validarDirectorio {
	#Para hacer todo más prolijo, se van a guardar los archivos que permitan identificar a 
	#los procesos en una carpeta llamada Ejercicio4 en /tmp
	if [[ ! -d /tmp/Ejercicio4 ]]; then #Si no existe la crea
		mkdir /tmp/Ejercicio4
	fi

	rutaAbsoluta=`realpath $directorio`

	#Se buscan todos los procesos "Ejercicio4" que se estén ejecutando
	#para ver si hay alguno que ya se esté ejecutando en el directorio actual
	if [[ -d /tmp/Ejercicio4 && `ls -A /tmp/Ejercicio4` ]]; then
		for archivo in /tmp/Ejercicio4/*.ej4; do
			rutaObtenida=`cat $archivo`
			if [[ $rutaObtenida = $rutaAbsoluta ]]; then
				echo "Ya hay un proceso ejecutándose en $rutaAbsoluta , saliendo"
				exit 0
			fi
		done
	fi

	#Los archivos tendrán como extensión .ej4 y como nombre su PID
	#Contendrán el directorio en el que están trabajando
	echo $rutaAbsoluta > /tmp/Ejercicio4/$$.ej4
}

#Cuando el script se termina de ejecutar, elimina todos los archivos creados en /tmp
#incluyendo la carpeta Ejercicio4 si es el único proceso ejecutándose
function limpiarTmp {

	archivo=`find /tmp/Ejercicio4 -name "$$.ej4"`
	rm $archivo

	if [[ ! `ls -A /tmp/Ejercicio4` ]]; then
		rmdir /tmp/Ejercicio4
	fi

	exit 0
}

#Si ya hay un proceso en el directorio, lo mata
#Si no lo hay, sale informando al usuario
function matarProceso {

	ruta=`realpath $directorio`

	if [[ -d /tmp/Ejercicio4 && `ls -A /tmp/Ejercicio4` ]]; then
		for archivo in /tmp/Ejercicio4/*.ej4; do
			rutaObtenida=`cat $archivo`
			if [[ $rutaObtenida = $ruta ]]; then
				PID=`basename $archivo .ej4`
				echo "Matando al proceso $PID del directorio $ruta"
				#TODO: hacer que al matar el proceso, no se muestre ningún mensaje que no sea el de arriba por pantalla
				kill $PID
				exit 0
			fi
		done
	fi

	echo "No hay proceso que matar en el directorio $ruta"
	exit 0
}

#Estas funciones se encargan de guardar los registros de cuando fueron creados o modificados los archivos en el directorio de origen
function archivoCreado {
	echo "[`date`]: El archivo $1$2 fue creado" >> $salida/registro.log
}

function archivoModificado {
	echo "[`date`]: El archivo $1$2 fue modificado" >> $salida/registro.log
}

#Cuando le mandan alguna de estas señales ejecuta limpiarTmp
trap limpiarTmp SIGINT SIGTERM

opcionesCortas=d:s:p:kh
opcionesLargas=directorio:,salida:,patron:,kill,shell,help

opts=`getopt -o $opcionesCortas -l $opcionesLargas -- "$@" 2> /dev/null`
if [ "$?" != "0" ]; then
    echo "Error parseando opciones, saliendo" >&2;
    exit 1;
fi

eval set -- $opts #no se que hace
#echo $1 $2

#Bucle para guardar los parámetros pasados al script
#TODO: arreglar un pequeño bug en el que por alguna razón se puede escribir --k --ki y --kil y los toma como argumentos válidos
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
    -p|--patron )
        patron="$2"
        shift 2
        ;;
    -k|--kill )
	kill=true
	shift
	;;
    -h|--help )
	mostrarAyuda
	exit 0
        ;;
    --shell )
	shell=true
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

validarParametros


if [[ "$kill" = "true" ]]; then
	matarProceso
elif [[ "$shell" = "true" ]]; then
	validarDirectorio

	#ESTO NO FUNCIONA, CREO QUE ENCONTRÉ UNA MANERA. MAÑANA VEO DE ARREGLARLO
	inotifywait -q -m -e modify,delete,create $directorio | while read DIRECTORY EVENT FILE; do
	    case $EVENT in
	        MODIFY* )
	            file_modified "$DIRECTORY" "$FILE"
		;;
		CREATE* )
	            file_created "$DIRECTORY" "$FILE"
	        ;;
	    esac
	done
fi

#Si no se le pasa el parámetro --shell, asume que se quiere ejecutar el script en el fondo.
#Para lograr esto, se ejecuta el mismo comando en una subshell
( ./Ejercicio4.sh -d "$directorio" -s "$salida" --shell &)
