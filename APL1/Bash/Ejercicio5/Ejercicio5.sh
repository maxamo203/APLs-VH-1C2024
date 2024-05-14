#! /bin/bash
#INTEGRANTES:
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÑAKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
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
	if [[ "$ids" != ""  && !("$ids" =~ ^([0-9])+(,[0-9]+)*$) ]]; then
		echo "ERROR: Ids no numericos"
		exit 3
	fi
}

#Cuando consultas nombre, te devuelve paginas (puede devolver solo una)
function consultarNombres() {
	IFS_VIEJO="$IFS"
	IFS=','

	for nombre in $nombres; do

		local resultadoFinal="$(jq --arg nombre "$nombre" '.[] | select(.name == $nombre)' "$destino")"
		if [[ "$resultadoFinal" = "" ]];then
			nombreApi="$(echo "$nombre" | sed -s 's/ /+/g')"
			local url="$urlBase/?name=$nombreApi"

			while true; do
				local resultado=$(curl -s "$url")

				if [[ "$(echo "$resultado" | jq -e '.error')" != "null" ]]; then
					echo "El nombre '$nombre' no traera resultados"
					break
				fi

				local resultadoFinal="$resultadoFinal""$(echo "$resultado" | jq '.results[]')"
				local url="$(echo "$resultado" | jq -r '.info.next')"

				if [[ "$url" = "null" ]];then
					break;
				fi
			done
		fi
		resultadoNombres="$resultadoNombres""$resultadoFinal"
	done

	IFS="$IFS_VIEJO"

	resultadoNombres="[$(echo "$resultadoNombres" | jq -c '.' | paste -sd "," -)]"
	resultadoNombres="$(echo "$resultadoNombres" | jq 'unique')"
}

#Cuando consultas id, devuelve 1 objeto o un array
function consultarIds() {
	if [[ "$ids" = "" ]]; then
		resultadoIds="[]"
		return
	fi
	IFS_VIEJO="$IFS"
	IFS=","

	for id in $ids; do
		if [ "$id" -ge 1 ] && [ "$id" -le 826 ]; then
			local resultado="$(jq ".[] | select(.id == $id)" $destino)"
			if [[ "$resultado" = "" ]];then
				local cadenaFallos="$cadenaFallos""$id,"
			fi
			resultadoIds="$resultadoIds""$resultado"
		else
			echo "ID: $id invalido, no traera resultados"
		fi
	done

	IFS="$IFS_VIEJO"

	if [[ "$cadenaFallos" != "" ]]; then
		local resultado="$(curl -s "$urlBase/$cadenaFallos" | jq '.[]')"
		resultadoIds="$resultadoIds""$resultado"
	fi

	resultadoIds="[$(echo "$resultadoIds" | jq -c '.' | paste -sd "," -)]"
}

trap manejarSigInt SIGINT

urlBase="https://rickandmortyapi.com/api/character"
destino="/home/$(whoami)/resultadoApiRYM.json"
tempIds="/tmp/tempIds.json"
tempNombres="/tmp/tempNombres.json"

if [ ! -f "$destino" ]; then
	echo "[]" > $destino
fi

procesarParametros "$@"
validarParametros

resultadoNombres=""
resultadoIds=""

consultarNombres
consultarIds

resultadoArchivo="$(cat "$destino")"
resultadoTotal="$(jq -n --argjson json1 "$resultadoNombres" --argjson json2 "$resultadoIds" '$json1 + $json2 | unique')"
jq -n --argjson json1 "$resultadoTotal" --argjson json2 "$resultadoArchivo" '$json1 + $json2 | unique' > $destino

printf "\nRESULTADOS\n-------------------------------------------\n"
echo "$resultadoTotal" | jq -r '.[] | "Name: \(.name)\nStatus: \(.status)\nSpecies: \(.species)\nGender: \(.gender)\nOrigin: \(.origin.name)\nLocation: \(.location.name)\n-------------------------------------------"'
