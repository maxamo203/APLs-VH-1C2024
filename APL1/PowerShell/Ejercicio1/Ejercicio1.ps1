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
    [System.IO.FileInfo]$salida,

    [Parameter(ParameterSetName = "pantalla")] [switch]$pantalla
)

#Write-Output "Parametros: $directorio $salida $pantalla"
$notasPorAlumno = @{} #va a ser un diccionario en donde la clave es el dni del alumno y el valor es un array que adentro va a tener diccionarios para cada materia (con su nota)
$Archivos = Get-ChildItem $directorio
foreach ($archivo in $Archivos) {
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
