#! /bin/sh

#####COSAS QUE FALTAN:

#validar parametros
#validar que solo haya numeros en las matrices


procesarArchivos() {
	if [ $separador = "|" ]
	then
		nuevaLinea="a"
	else
		nuevaLinea="|"
	fi

	paste -s -d $nuevaLinea matriz1.txt matriz2.txt | awk -v separador="$separador" -v nuevaLinea="$nuevaLinea" -F $separador '

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
	function cargarMatriz(arr,matriz){
		for (i in arr){
			split(arr[i],fila,separador)
			for (j in fila){
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
		cargarMatriz(arr,mat1)
		filas1=length(arr)
		columnas1=length(mat1[1])
	}
	NR == 2 {
		#Cargo Matriz 2
		split($0,arr,nuevaLinea)
		cargarMatriz(arr,mat2)
		filas2=length(arr)
		columnas2=length(mat2[1])
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


procesarParametros() {
	#parametros:
	# -m1 / --matriz1
	# -m2 / --matriz2
	# -s / --separador

	params=$(echo $@ | sed -r "s/-m1/-f/" | sed -r "s/-m2/-t/")
	set -- "$params"

	opcionesCortas=f:t:s:
	opcionesLargas=matriz1:,matriz2:,separador:

	opts=$(getopt -o $opcionesCortas -l $opcionesLargas -- $@)

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
			*)
				echo "la opcion especificada $1 no existe"
				exit 1
		esac
	done
}

validarParametros() {
	if [ "$arch1" = "" ]; then
		echo "No se proporciona ruta de la matriz 1"
		exit 1;
	fi
	if [ "$arch2" = "" ]; then
		echo "No se proporciona ruta de la matriz 2"
		exit 1;
	fi
	if [ "$separador" = "-" ]; then
		echo "El separador no puede ser '-'"
		exit 1;
	elif [ "$separador" = "" ]; then
			separador=","
	fi
}

procesarParametros $@
validarParametros
procesarArchivos












