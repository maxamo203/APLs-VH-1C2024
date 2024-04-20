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
    if [[ ! -z "$kill" && ( ! -z "$salida" || ! -z "$patron" ) ]]; then
	echo "El parámetro -k/--kill solo puede ser usado junto con -d/--directorio"
	exit 7
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

	archivoEj4=`find /tmp/Ejercicio4 -name "$$.ej4"`
	rm $archivoEj4
	archivoNlog=`find /tmp/Ejercicio4 -name "$$.nlog"`
	rm $archivoNlog

	if [[ ! `ls -A /tmp/Ejercicio4` ]]; then
		rmdir /tmp/Ejercicio4
	fi

	kill "$notifyPID" #Matamos al notifywait
	exit 0
}

#Si ya hay un proceso en el directorio, lo mata
#Si no lo hay, informa al usuario
function matarProceso {

	ruta=`realpath $directorio`

	if [[ -d /tmp/Ejercicio4 && `ls -A /tmp/Ejercicio4` ]]; then
		for archivo in /tmp/Ejercicio4/*.ej4; do
			rutaObtenida=`cat $archivo`
			if [[ $rutaObtenida = $ruta ]]; then
				PID=`basename $archivo .ej4`
				echo "Matando al proceso $PID del directorio $ruta"
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

function hacerBackup {

	archivoSalida="$salida/$1.tar"

	#Nota: tar se reusa cobardemente a crear un archivo vacío.
	if [[ ! -s "$1" ]]; then
		echo "No se puede hacer un backup del archivo $1 ya que está vacío (Esto tendría que estar en el registro)"
		return 1
	fi

	#Si no hay un archivo de backup lo tenemos que crear
	if [[ ! -e "$archivoSalida" ]]; then
		tar -cf $archivoSalida --transform="s,^,`date +%Y%m%d-%H%M%S` ," $1
	fi

	gzip $archivoSalida
}

function observarDirectorio {

	#El notify lo ejecuto en el fondo para que no haga lío
	inotifywait -m -q -e create,modify "$directorio" >> /tmp/Ejercicio4/$$.nlog &
	notifyPID="$!" #Guardo su PID para poder matarlo después
	ultimaLinea=""
	
	while true; do
		#Agarra la última linea del archivo donde inotifywait está guardando la salida
		nuevaLinea=`tail -n 1 /tmp/Ejercicio4/$$.nlog`

		#Esto funciona así, como es un dolor de huevos usar inotify wait de una en el script por múltiples razones
		#lo que hice acá fue que el inotify guardara su output en un archivo temporal .nlog
		#y que el script del ejercicio4 leyera la última línea que está ahí.
		
		#De momento, creo que tiene un error medio grave, si se modifica el archivo varias veces seguidas, no lo nota.
		#Lo mismo si se crea el archivo varias veces seguidas
		if [[ "$nuevaLinea" != "$ultimaLinea" ]]; then
			ultimaLinea="$nuevaLinea"

			evento=`echo $ultimaLinea | awk '{print $2}'`
			archivoAfectado=`echo $ultimaLinea |awk '{print $3}'`

			sed '$d' /tmp/Ejercicio4/$$.nlog > /tmp/Ejercicio4/$$.nlog

			case "$evento" in
				"CREATE")
					archivoCreado $archivoAfectado
				;;
				"MODIFY")
					archivoModificado $archivoAfectado
				;;
			esac

			hacerBackup $archivoAfectado

		fi
	done
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
	
	notifyPID=""
	observarDirectorio
else
	#Si no se le pasa el parámetro --shell, asume que se quiere ejecutar el script en el fondo.
	#Para lograr esto, se ejecuta el mismo comando en una subshell
	( ./Ejercicio4.sh -d "$directorio" -s "$salida" --shell &)
fi

