#! /bin/sh

#####COSAS QUE FALTAN:

#parametros
#dar los datos de la matriz resultante
#validar que solo haya numeros en las matrices
#agregar posibilidad de otro caracter separador

paste -s -d "|" matriz1.txt matriz2.txt | awk -F "," '
function validarMatriz(matriz,filas,columnas,errorMatriz) {
	if ( filas == 0 ){
		print "ERROR: El archivo de la matriz " errorMatriz " esta vacio"
		exit 1
	}
	for ( i in matriz ){
		if ( length(matriz[i]) != columnas ){
			print "ERROR: La matriz numero " errorMatriz " tiene filas con distinta cantidad de columnas"
			exit 1
		}
	}
}
function cargarMatriz(arr,matriz){
	for (i in arr){
		split(arr[i],fila,",")
		for (j in fila){
			matriz[i][j]=fila[j]
		}
	}
}

NR == 1 {
	#Cargo Matriz 1
	split($0,arr,"|")
	cargarMatriz(arr,mat1)
	filas1=length(arr)
	columnas1=length(mat1[1])
	validarMatriz(mat1,filas1,columnas1,1)
}
NR == 2 {
	#Cargo Matriz 2
	split($0,arr,"|")
	cargarMatriz(arr,mat2)
	filas2=length(arr)
	columnas2=length(mat2[1])
	validarMatriz(mat2,filas2,columnas2,2)
}
END {
	#Valido la multiplicacion
	if ( columnas1 != filas2 ){
		print "ERROR: las columnas de la matriz 1 no coinciden con las filas de la matriz 2"
		exit 1
	}
	##Multiplico
	for( i=1 ; i<=filas1 ; i++){
		for( j=1 ; j<=columnas2 ; j++ ){
			acum=0
			for( k=1 ; k<=columnas1 ; k++ ){
				acum+=mat1[i][k] * mat2[k][j]
			}
			resultado=resultado acum" "
		}
		print resultado
		resultado=""
	}
} '
