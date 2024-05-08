#! /bin/bash
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÑAKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
function mostrarAyuda() {
	echo "Modo de uso:"
	echo "-m1|--matriz1 <path> * --> Indica la ruta del archivo que contiene la primer matriz"
	echo "-m2|--matriz2 <path> * --> Indica la ruta del archivo que contiene la segunda matriz"
	echo "-s|--separador --> Indica el caracter separador de los numeros de la matriz, si no se completa, se asigna el separador por defecto (',')"
	echo "-h|--help --> Muestra la ayuda y omite el resto de parametros"
	echo "* : PARAMETRO OBLIGATORIO"
}

function procesarArchivos() {
		if [ $separador = "|" ]
		then
			nuevaLinea="a"
		else
			nuevaLinea="|"
		fi

		paste -s -d "$nuevaLinea" "$arch1" "$arch2" | awk -v separador="$separador" -v nuevaLinea="$nuevaLinea" -F $separador '

		function validarMatriz(matriz,filas,columnas,errorMatriz) {
			if ( filas == 0 ){
				print "ERROR: El archivo de la matriz " errorMatriz " esta vacio"
				salir=1
				exit 1
			}
			for ( i in matriz ){
				if ( length(matriz[i]) != columnas ){
					print "ERROR: La matriz numero " errorMatriz " tiene filas con distinta cantidad de columnas"
					salir=1
					exit 1
				}
			}
		}
		function cargarMatriz(arr,matriz,errorMatriz){
			for (i in arr){
				split(arr[i],fila,separador)
				for (j in fila){
					if ( fila[j] !~ /^(\-?)([0-9]+)$/ ){
						print "ERROR: Hay elementos de la matriz " errorMatriz " que no son numericos"
						salir=1
						exit 1
						}
					matriz[i][j]=fila[j]
				}
			}
		}
		function multiplicarMatrices(){
			print "Matriz resultado:"
			print ""
			for( i=1 ; i<=filas1 ; i++){
				for( j=1 ; j<=columnas2 ; j++ ){
					acum=0
					for( k=1 ; k<=columnas1 ; k++ ){
						acum+=mat1[i][k] * mat2[k][j]
					}
					resultado=resultado acum" "
				}
				print "   "resultado
				resultado=""
			}
		}

		NR == 1 {
			#Cargo Matriz 1
			split($0,arr,nuevaLinea)
			cargarMatriz(arr,mat1,1)
			filas1=length(arr)
			columnas1=length(mat1[1])
			validarMatriz(mat1,filas1,columnas1,1)
		}
		NR == 2 {
			#Cargo Matriz 2
			split($0,arr,nuevaLinea)
			cargarMatriz(arr,mat2,2)
			filas2=length(arr)
			columnas2=length(mat2[1])
			validarMatriz(mat2,filas2,columnas2,2)
		}
		END {
			if ( salir == 1 ) exit 1;
			#Valido la multiplicacion
			if ( columnas1 != filas2 ){
				print "ERROR: las columnas de la matriz 1 no coinciden con las filas de la matriz 2"
				exit 1
			}
			multiplicarMatrices()
			print ""
			print "--------------------------"
			print "La matriz resultante:"
			print ""
			print "Es de orden " filas1 "x" columnas2
			print (filas1 == columnas2 ? "Es cuadrada" : "No es cuadrada")
			print (columnas2 == 1 ? "Es una matriz columna" : "No es una matriz columna")
			print (filas1 == 1 ? "Es una matriz fila" : "No es una matriz fila")
		} '
}


function procesarParametros() {
		#parametros:
		# -m1 / --matriz1
		# -m2 / --matriz2
		# -s / --separador


		opcionesCortas=f:t:s:h
		opcionesLargas=matriz1:,matriz2:,separador:,help

		opts=`getopt -o $opcionesCortas -l $opcionesLargas -- "$@" 2> /dev/null`
		if [ "$?" != 0 ];then
			echo "Error en las opciones especificadas al ejecutar el archivo" >&2
			exit 1
		fi

		eval set -- "$opts"

		while true; do
			case $1 in
				-f|--matriz1)
					arch1=$2
					shift 2
					;;
				-t|--matriz2)
					arch2=$2
					shift 2
					;;
				-s|--separador)
					separador="$2"
					shift 2
					;;
				--)
					shift
					break
					;;
				-h|--help)
					mostrarAyuda
					exit 0
					;;
				*)
					echo "la opcion especificada $1 no existe"
					exit 1
			esac
		done
}

function validarParametros() {
		if [[ "$separador" =~ (\-) ]]; then
			echo "El separador no puede ser '-'"
			exit 2
		elif [[ "$separador" =~ [0-9] ]]; then
			echo "El separador no puede contener caracteres numericos"
			exit 2
		elif [ "$separador" = "" ]; then
				separador=","
		fi

		if [ ! -f "$arch1" ]; then
			echo "No se proporciona una ruta valida para la matriz 1"
			exit 2
		fi

		if [ ! -f "$arch2" ]; then
			echo "No se proporciona una ruta valida para la matriz 2"
			exit 2
		fi
}


#PROBLEMA DEL EJERCICIO
#pide que existan las opciones -m1 y m2... Estas opciones deben ser opciones CORTAS
#las opciones cortas solo pueden tener un caracter
#Solucion que se me ocurrio: reemplazar los -m1 y -m2 por otro caracter y en el getopt usar ese caracter
#Al principio hacia:
	#params=$(echo $@ | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
	#set -- "$params"
#La primer linea reemplaza los -m1 y -m2. La segunda linea hace que la variable 'params' sea el '$@'
#El problema de esto es que cuando haces la siguiente linea:
	#opts=`getopt -o $opcionesCortas -l $opcionesLargas -- "$@" 2> /dev/null`
#Toda la linea de parametros se rompe... Para que no se rompa, la variable '$@' hay que ponerla sin ""
#El problema? Que si pasas '$@' sin "", no va a poder separar bien si le paso un directorio con espacios
#La solucion que se me ocurrio es mirar cada parametro, reemplazar en cada uno si es necesario y pasarle cada parametro uno por uno a una funcion

uno=$(echo "$1" | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
dos=$(echo "$2" | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
tres=$(echo "$3" | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
cuatro=$(echo "$4" | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
cinco=$(echo "$5" | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
seis=$(echo "$6" | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")

procesarParametros "$uno" "$dos" "$tres" "$cuatro" "$cinco" "$seis"
validarParametros
procesarArchivos

