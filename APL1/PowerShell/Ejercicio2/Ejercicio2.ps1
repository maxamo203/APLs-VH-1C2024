<#
.SYNOPSIS
	Este script realiza la multiplicacion de dos matrices cargadas en archivos separados y muestra el resultado por pantalla.
.DESCRIPTION
	El script carga dos matrices desde archivos separados y realiza la multiplicacion de las mismas.
	Se deben especificar las rutas de los archivos de las matrices y es opcional la especificacion del separador de valores.
.PARAMETER matriz1
	Ruta del archivo de la primera matriz.
.PARAMETER matriz2
	Ruta del archivo de la segunda matriz.
.PARAMETER separador
	Carácter separador de valores. Opcional, por defecto es una coma (`,`).
.EXAMPLE
	.\Ejercicio2.ps1 -matriz1 "C:\Ruta\Matriz1.txt" -matriz2 "C:\Ruta\Matriz2.txt" -separador ";"
	Realiza la multiplicacion de las matrices contenidas en los archivos Matriz1.txt y Matriz2.txt, utilizando el punto y coma (;) como separador de valores.
.FUNCTIONALITY
	Multiplicacion de matrices
#>
#INTEGRANTES:
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÑAKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
Param(
  [Parameter(Mandatory=$true)]
  [ValidateScript({
    if (-not (Test-Path $_)) {
        throw "La ruta $_ no existe."
    }
    $true
  })]
  [string] $matriz1,

  [Parameter(Mandatory=$true)]
  [ValidateScript({
    if (-not (Test-Path $_)) {
        throw "La ruta $_ no existe."
    }
    $true
  })]
  [string] $matriz2,

  [Parameter(Mandatory=$false)]
  [ValidateScript({
    if ($_ -eq "-" -or $_ -match '\d') {
        throw "El separador no puede ser '-' o un caracter numerico."
    }
    $true
  })]
  [string] $separador = ","
)
function ProcesarArchivos{
	# Función para validar una matriz
	function Validar-Matriz {
		param (
			[string[]] $ContenidoMatriz,
			[string] $NombreMatriz
		)

		# Verifica si la matriz está vacía
		if (-not $ContenidoMatriz) {
			Write-Error "ERROR: El archivo de la matriz $NombreMatriz esta vacío"
			exit 1
		}

		# Verifica si todas las filas tienen la misma cantidad de columnas
		$ColumnasPrimeraFila = ($ContenidoMatriz[0] -split $separador).Count
		foreach ($fila in $ContenidoMatriz) {
			$columnas = ($fila -split $separador).Count
			if ($columnas -ne $ColumnasPrimeraFila) {
				Write-Error "ERROR: La matriz $NombreMatriz tiene filas con distinta cantidad de columnas"
				exit 1
			}
		}
		
		# Verifica si todos los elementos son numéricos
		foreach ($fila in $ContenidoMatriz) {
			foreach ($elemento in ($fila -split $separador)) {
				if ($elemento -notmatch '^[-]?\d+$') {
					Write-Error "ERROR: Hay elementos de la matriz $NombreMatriz que no son numericos o el separador ingresado es incorrecto"
					exit 1
				}
			}
		}
	}

	# Función para multiplicar las matrices
	function Multiplicar-Matrices {
		param (
			[string[]] $Matriz1,
			[string[]] $Matriz2
		)

		# Obtener dimensiones de las matrices
		$FilasMatriz1 = $Matriz1.Count
		$ColumnasMatriz1 = ($Matriz1[0] -split $separador).Count
		$ColumnasMatriz2 = ($Matriz2[0] -split $separador).Count

		# Crear matriz resultado
		$MatrizResultado = @()

		# Realizar la multiplicación de las matrices
		for ($i = 0; $i -lt $FilasMatriz1; $i++) {
			$fila = @()
			for ($j = 0; $j -lt $ColumnasMatriz2; $j++) {
				$acum = 0
				for ($k = 0; $k -lt $ColumnasMatriz1; $k++) {
					$acum += [int]($Matriz1[$i] -split $separador)[$k] * [int]($Matriz2[$k] -split $separador)[$j]
				}
				$fila += $acum
			}
			$MatrizResultado += ,$fila
		}

		# Mostrar la matriz resultado por pantalla
		Write-Host "Matriz resultado:"
		Write-Host ""
		foreach ($fila in $MatrizResultado) {
			Write-Host ("   " + ($fila -join " "))
		}
		
		# Mostrar información adicional
		Write-Host ""
		Write-Host "--------------------------"
		Write-Host "Informacion adicional:"
		Write-Host ""
		Write-Host "Orden de la matriz: $($FilasMatriz1)x$($ColumnasMatriz2)"
		if($($FilasMatriz1 -eq $ColumnasMatriz2)){
			Write-Host "Es cuadrada"
		} else{
				Write-Host "No es cuadrada"
		}
		if($($FilasMatriz1 -eq 1)){
			Write-Host "Es una matriz fila"
		} else{
				Write-Host "No es una matriz fila"
		}
		if($($ColumnasMatriz2 -eq 1)){
			Write-Host "Es una matriz columna"
		} else{
				Write-Host "No es una matriz columna"
		}	
	}

	# Leer contenido de los archivos de las matrices
	$ContenidoMatriz1 = (Get-Content $matriz1) -split "`n"
	$ContenidoMatriz2 = (Get-Content $matriz2) -split "`n"

	# Validar las matrices
	Validar-Matriz -ContenidoMatriz $ContenidoMatriz1 -NombreMatriz "1"
	Validar-Matriz -ContenidoMatriz $ContenidoMatriz2 -NombreMatriz "2"	
	
	# Verificar que la cantidad de columnas de la primera matriz sea igual a la cantidad de filas de la segunda matriz
	$ColumnasMatriz1 = ($ContenidoMatriz1[0] -split $separador).Count
	$FilasMatriz2 = $ContenidoMatriz2.Count
	
	if ($ColumnasMatriz1 -ne $FilasMatriz2) {
		Write-Error "ERROR: La cantidad de columnas de la primera matriz no coincide con la cantidad de filas de la segunda matriz"
		exit 1
	}
	
	Multiplicar-Matrices -Matriz1 $ContenidoMatriz1 -Matriz2 $ContenidoMatriz2
	
}
# Llamada a la función principal
ProcesarArchivos
