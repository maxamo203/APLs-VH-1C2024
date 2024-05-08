#encoding: UTF-8

<#
.SYNOPSIS
Esta funcion analiza los archivos de texto en un directorio y genera un informe.

.DESCRIPTION
La funcion realiza las siguientes tareas:
- Contabiliza la cantidad de ocurrencias de palabras de diferentes longitudes.
- Identifica la(s) palabra(s) mas frecuente(s).
- Calcula la cantidad total de palabras.
- Determina el promedio de palabras por archivo.
- Encuentra el caracter mas repetido.

.PARAMETER directorio
Ruta del directorio que contiene los archivos a analizar.

.PARAMETER extension
Especifica la extensión de los archivos a analizar. Opcional.

.PARAMETER separador
Caracter utilizado como separador de palabras. Opcional. Por defecto, es el espacio (" ").

.PARAMETER omitir
Array de caracteres que deben ser omitidos al analizar las palabras del archivo.

.EXAMPLE
.\ejercicio.ps1 -directorio .\misArchivos

.EXAMPLE
.\ejercicio.ps1 -directorio .\misArchivos -extension .txt -omitir @("`n", "`r")
#>
#INTEGRANTES:
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÑAKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        #Chequeo que el directorio proporcionado exista
        if (! (Test-Path $_)) {
            throw "El directorio $_ no existe o no es un directorio valido."
        }
        return $true
    })]
    [string]
    $directorio,
    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]    
    [ValidatePattern('^...$')]
    [string]
    $extension="*",
    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^.$')]
    [string]
    $separador=" ",    
    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [array]
    $omitir=@()
)

#omite salto de linea
$omitir += "`n"
$archivos=$(Get-ChildItem -Path "$directorio" -Filter "*.$extension")

#Lanza excepcion si no encontro archivos en el directorio con la extension proporcionada
if( -not $archivos -and -not ($extension -eq '*')){
    throw "El directorio $directorio no contiene ningun archivo con la extension $extension."
}

#Lanza excepcion si no encontro archivos en el directorio
if( -not $archivos){
    throw "El directorio $directorio no contiene ningun archivo."
}

#funcion que devuelve 1 si el string contiene un caracter del array "omitir"
function contieneOmitir(){
    Param(
        [string]
        $cadena
    )
    #Esto chequea que la cadena no este vacia, si lo esta, lo omite
    if([String]::IsNullOrWhiteSpace($cadena)){
        return 1
    }
    #Recorro la cadena omitir para chequear que la palabra no tenga un caracter del array
    foreach ($char in $omitir){
        if($cadena.Contains($char)){
            return 1
        }
    }
}

#inicializo las listas y variables
$listaPalabras=@{}
$listaLongitudes=@{}
$listaCaracteres=@{}
$cantidadDePalabras=0

foreach ($archivo in $archivos){
    #obtengo un array de registros del archivo separados por el separador
    $registros= Get-Content $archivo.FullName -Delimiter $separador
    foreach ($registro in $registros){
        #creo un array de cadenas con el resultado de splitear por cualquier cosa que no sea numero o letra
        #esto se hace por si hay caracteres no deseados entre palabras, como por ejemplo: Arbol(TDA)
        #dando como resultado este array: ("Arbol", "TDA")
        $cadenasRegistros = $registro -split '[^\p{L}\p{N}áéíóúüÁÉÍÓÚÜ]+'
        foreach ($cadenaRegistros in $cadenasRegistros ){
            #quito del registro todo lo que no sea numeros o letras
            $cadenaRegistros = $cadenaRegistros -replace '[^\p{L}\p{N}áéíóúüÁÉÍÓÚÜ]', ''
            #si contieneOmitir devuelve "1" se saltea el registro
            if(-not (contieneOmitir $cadenaRegistros)){
                #cuenta las palabras
                $listaPalabras[$cadenaRegistros]++
                #cuenta las longitudes de las palabras
                $listaLongitudes[$cadenaRegistros.Length]++
                #cuenta la cantidad de palabras
                $cantidadDePalabras++
                #creo array de caracteres para recorrerlo
                $caracteres=$cadenaRegistros.ToCharArray()
                foreach ($caracter in $caracteres){
                        #cuenta la cantidad de caracteres
                        $listaCaracteres[$caracter]++
                }
            }
        }
    }
}

##NOTA: Se requiere usar el metodo "GetEnumerator" para obtener un enumerador que permite recorrer los elementos de una colección uno por uno.
##      Tanto para pasar el array por pipelining a la funcion Sort o Where, o como para recorrerlo y mostrarlo en pantalla, se necesita el enumerador.


#creo lista ordenada por longitud
$listaLongitudesOrdenada = $listaLongitudes.GetEnumerator() | Sort-Object -Property Key

#creo lista ordenada por cantidad de palabras de forma decendente para obtener la maxima cantidad de repeticiones
$listaPalabrasOrdenada = $listaPalabras.GetEnumerator() | Sort-Object -Property Value -Descending
$mayorValor = $listaPalabrasOrdenada[0].Value
#hago una lista con las palabras que tengan como repeticiones la maxima cantidad de repeticiones
$palabrasMasFrecuentes = $listaPalabrasOrdenada.GetEnumerator() | Where-Object { $_.Value -eq $mayorValor }

#obtengo el promedio de palabras por archivo
$promedioPalabrasxArchivo=$cantidadDePalabras/$($archivos.Count)


#creo lista ordenada por cantidad de caracteres de forma decendente para obtener la maxima cantidad de repeticiones
$listaCaracteresOrdenada = $listaCaracteres.GetEnumerator() | Sort-Object -Property Value -Descending
$mayorValor = $listaCaracteresOrdenada[0].Value
#hago una lista con los caracteres que tengan como repeticiones la maxima cantidad de repeticiones
$caracteresMasFrecuentes = $listaCaracteresOrdenada.GetEnumerator() | Where-Object { $_.Value -eq $mayorValor }


#Imprimo el informe

# foreach ($palabra in $listaPalabras.GetEnumerator()) {
#     Write-Host "$($palabra.Key) con $($palabra.Value) ocurrencia(s)"
# }

Write-Host "
------------------INFORME------------------
La cantidad de ocurrencias de palabras de X caracteres"
foreach($longitud in $listaLongitudesOrdenada){
    if($longitud.Key -eq 1){
        Write-Host "Palabras de $($longitud.Key) caracter: $($longitud.Value)"
    }
    else{
        Write-Host "Palabras de $($longitud.Key) caracteres:  $($longitud.Value)"
    }
}

Write-Host "

La(s) Palabra(s) mas frecuente(s):"
foreach ($palabra in $palabrasMasFrecuentes) {
    Write-Host "`"$($palabra.Key)`" con $($palabra.Value) ocurrencia(s)"
}

Write-Host "

Cantidad total de palabras: $cantidadDePalabras"

Write-Host "

Promedio de palabras por archivo: $promedioPalabrasxArchivo"

Write-Host "

El/Los caracter(es) mas frecuente(s):"
foreach ($caracter in $caracteresMasFrecuentes) {
    Write-Host "`"$($caracter.Key)`" con $($caracter.Value) ocurrencia(s)"
}

Write-Host "

"

