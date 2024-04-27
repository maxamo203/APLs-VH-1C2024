#! /bin/bash

function mostrarAyuda() {
	echo "Modo de uso:"
	echo "-i|--id <ID> --> Id o Ids de los personajes a buscar, separados por ','"
	echo "-n|--nombre <NOMBRE> --> Nombre o nombres de los personajes a buscar, separados por ','"
	echo "-h|--help --> Muestra la ayuda y omite el resto de parametros"
	echo "Pueden usarse varios parametros de busqueda a la vez pero siempre es necesario usar al menos uno"
	echo "Aclaracion: El .json sera creado en el directorio de inicio del usuario con el nombre 'resultadoApiRYM.json'"
}


function manejarSigInt() {
	if [ -f $tempIds ]; then rm $tempIds; fi
	if [ -f $tempNombres ]; then rm $tempNombres; fi
	if [ -f $destino ]; then rm $destino; fi
	exit 1
}

function procesarParametros(){
	#parametros
	#-i / --id
	#-n / --nombre

	opcionesCortas=i:n:hd:a:
	opcionesLargas=id:,nombre:,help,directorio:,archivo:

	opts=`getopt -o $opcionesCortas -l $opcionesLargas -- "$@" 2> /dev/null`
	if [ "$?" != 0 ]; then
		echo "Error en las opciones especificadas al ejecutar el archivo" >&2
		exit 1
	fi

	eval set -- "$opts"

	while true; do
		case $1 in
			-i|--id)
				ids="$2"
				shift 2
				;;
			-n|--nombre)
				nombres="$2"
				shift 2
				;;
			-h|--help)
				mostrarAyuda
				exit 0
				;;
			--)
				shift
				break
				;;
			*)
				echo "La opcion especificada $1 no existe"
				exit 2
		esac
	done
}

function validarParametros() {
	if [[ "$ids" = "" && "$nombres" = "" ]]; then
		echo "No se ha ingresado ningun parametro... Saliendo"
		exit 3
	fi
	nombres="$(echo "$nombres" | sed -s 's/ /+/g')"
}

#Puedo pasar una lista de ids a la API
#No puedo pasar una lista de nombres a la API, tengo que iterar

#Cuando consultas nombre, te devuelve paginas (puede devolver solo una)
function consultarNombres() {
	if [ "$nombres" = "" ];then
		echo '[' >> $1
		echo ']' >> $1
		return
	fi

	IFS_VIEJO="$IFS"
	IFS=','

	for nombre in $nombres; do
		local url="$urlBase""/?name=""$nombre"

		while true; do
			local resultado=$(curl -s "$url")

			if [[ "$(echo "$resultado" | jq -e '.error')" != "null" ]]; then
				nombre="$(echo "$nombre" | sed -s 's/+/ /g')"
				echo "El nombre '$nombre' no traera resultados"
				break
			fi

			local resultadoFinal="$resultadoFinal""$(echo "$resultado" | jq '.results[]')"
			local url="$(echo "$resultado" | jq -r '.info.next')"

			if [[ "$url" = "null" ]];then
				break;
			fi
		done
	done

	IFS="$IFS_VIEJO"

	local resultadoFinal="[$(echo "$resultadoFinal" | jq -c '.' | paste -sd "," -)]"

	echo "$resultadoFinal" | jq 'unique' >> $1
}

#Cuando consultas id, devuelve 1 objeto o un array
function consultarIds() {
	IFS_VIEJO="$IFS"
	IFS=","

	local idsValidos=""
	for id in $ids; do
		if [ "$id" -ge 1 ] && [ "$id" -le 826 ]; then
			local idsValidos="$idsValidos""$id"","
		else
			echo "ID: $id invalido"
		fi
	done

	#ids validos termina en ','. Por lo tanto, la consulta a la API SIEMPRE devuelve un array

	IFS="$IFS_VIEJO"

	if [ "$idsValidos" = "" ];then
		echo '[' >> $1
		echo ']' >> $1
		return
	fi

	local url="$urlBase""/""$idsValidos"
	local resultado=$(curl -s "$url")

	echo "$resultado" | jq '.' >> $1
}

trap manejarSigInt SIGINT

urlBase="https://rickandmortyapi.com/api/character"
destino="/home/$(whoami)/resultadoApiRYM.json"
tempIds="/tmp/tempIds.json"
tempNombres="/tmp/tempNombres.json"

touch $tempIds
touch $tempNombres

procesarParametros "$@"
validarParametros

consultarNombres $tempNombres
consultarIds $tempIds
jq -s '.[0] + .[1] | unique' $tempNombres $tempIds > $destino

rm $tempIds
rm $tempNombres

printf "\nRESULTADOS\n-------------------------------------------\n"
jq -r '.[] | "Name: \(.name)\nStatus: \(.status)\nSpecies: \(.species)\nGender: \(.gender)\nOrigin: \(.origin.name)\nLocation: \(.location.name)\n-------------------------------------------"' $destino
