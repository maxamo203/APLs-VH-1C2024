<#
.SYNOPSIS
	Este script realiza un informe de notas de alumnos, separado por alumno
.DESCRIPTION
	El script carga los archivos csv que se encuentran en un directorio, y para cada alumno calcula su nota en cada materia 
.PARAMETER directorio
	Ruta del directorio donde se encuentran los archivos de notas
.PARAMETER salida
	Indica que el resultado se enviara a un archivo json con el nombre especificado
.PARAMETER pantalla
	Indica que el resultado se muestra por pantalla, no se puede usar junto con -salida
.EXAMPLE
	.\Ejercicio1.ps1 -directorio "../Notas Ejercicio1" -salida ./resultado.json
.EXAMPLE
	.\Ejercicio1.ps1 -directorio "../Notas Ejercicio1" -pantalla
.FUNCTIONALITY
	Analisis de notas
#>
#INTEGRANTES:
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÑAKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
[CmdletBinding(DefaultParameterSetName = 'salida')]
Param(
    [Parameter(Mandatory = $True)]
    [ValidateScript({
            if (Test-Path -Path $_ -PathType Container) { #se fija si existe el directorio
                $true
            }
            else {
                throw "La ruta especificada no es válida o no existe."
            }
        })] [System.IO.DirectoryInfo]$directorio,

    [Parameter(ParameterSetName = "salida")]
    [ValidateScript({
            if ($_ -match "\.\w+$") { $true } else { throw "El formato del archivo no es válido." }
        })]
    [System.IO.FileInfo]$salida = "./salida.json",

    [Parameter(ParameterSetName = "pantalla")] [switch]$pantalla
)

#Write-Output "Parametros: $directorio $salida $pantalla"
$notasPorAlumno = @{} #va a ser un diccionario en donde la clave es el dni del alumno y el valor es un array que adentro va a tener diccionarios para cada materia (con su nota)
$Archivos = Get-ChildItem $directorio
if($Archivos.Count -eq 0){
    Write-Warning "Directorio de notas vacio, saliendo"
    exit 0
}
foreach ($archivo in $Archivos) {
    if($archivo.Extension -ne ".csv"){
        Write-Warning "Se encontro un archivo que no es .csv: $($archivo.Name), omitiendo"
        continue
    }
    $cantNotas = (Get-Content $archivo.FullName -TotalCount 1).Split(',').Count - 1
    $csvContent = Import-Csv -Path $archivo.FullName
    $ponderacion = 10 / $cantNotas
    foreach ($registro in $csvContent) {
        $dni = $registro."DNI-Alumno"
        $nota = 0
        for ($i = 1; $i -le $cantNotas; $i++) {
            #itera notas
            if ($registro."nota-ej-$i" -eq 'b') {
                $nota += $ponderacion
            }
            elseif ($registro."nota-ej-$i" -eq 'r') {
                $nota += ($ponderacion / 2)
            }
        }
        $nota = [Math]::Truncate($nota)
        
        if (-not $notasPorAlumno.ContainsKey($dni)) {
            $notasPorAlumno[$dni] = @()  # Asegura que haya un array para empezar
        }

        # Añade un nuevo diccionario al array 
        $notasPorAlumno[$dni] += @{
            materia = [int]$archivo.basename
            nota    = [int]$nota
        }

    }
}
$notasParaJson = @()
foreach ($dni in $notasPorAlumno.Keys) { #itera el array notasPorAlumno y pone en notasParaJson el objeto Final que se imprimira en json
    $notasParaJson += @{
        dni   = $dni
        notas = $notasPorAlumno[$dni]
    }
}
$json = @{notas = $notasParaJson} | ConvertTo-Json -Depth 4 #el depth es para que tome el detalle de cada alumno

if ($pantalla -eq $true){
    Write-Output $json
}
else{
    $json > $salida
}
