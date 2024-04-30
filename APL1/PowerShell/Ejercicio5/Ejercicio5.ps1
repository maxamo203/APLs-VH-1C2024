param(

    [Parameter(Mandatory=$false, ParameterSetName="input")]
    [int[]]$id,
    [Parameter(Mandatory=$false, ParameterSetName="input")]
    [string[]]$nombre

)
function peticion{
    param(
        [ScriptBlock]$peticion, 
        [string]$datoPedido
    )
    try{ 
        $res = & $peticion

        
        #Write-Output $res 
        
        $global:Resultados += $res
    }
    catch{
       # Accede al objeto de respuesta de la excepción
       $responseError = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Warning "$($responseError.error): $datoPedido"
    }
}
function parsearObjeto{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [Object]$value #solo se pasa un objeto a la vez
    )
    Process{
        return ($value | Select-Object -Property id,name,status,species,gender,
            @{Name = 'Origin'; Expression={$_.origin.name}},
            @{Name = 'Location'; Expression={$_.location.name}})
    }
}
function imprimirObjeto{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [Object]$value #solo se pasa un objeto a la vez
    )
    Process {
        Write-Output "Character info:"
        Write-Output "ID: $($value.id)"
        Write-Output "Name: $($value.name)"
        Write-Output "Status: $($value.status)"
        Write-Output "Species: $($value.species)"
        Write-Output "Gender: $($value.gender)"
        Write-Output "Origin: $($value.Origin)"
        Write-Output "Location: $($value.Location)"
        Write-Output ""  # Añade una línea en blanco para separar los personajes
    }
}
function petitcionPorId{
    param ([int[]]$id)
    if($id.Count -eq 0){
        return
    }
    peticion -peticion {Invoke-RestMethod -Uri "https://rickandmortyapi.com/api/character/$($id -join ",")" | parsearObjeto} -datoPedido $id
}
function petitcionPorNombre{
    param ([string[]]$nombres)
    if($nombres.Count -eq 0){
        return
    }
    peticion -peticion {$nombres | ForEach-Object {(Invoke-RestMethod -Uri "https://rickandmortyapi.com/api/character/?name=$_").results | parsearObjeto } } -datoPedido $nombres
}


function buscarEnArchivo{
    param(
        # [Parameter(Mandatory)]
        # [ref]$nombres,

        [Parameter(Mandatory)]
        [ref]$ids
    )
    if(-not( Test-Path "cache.ej5")){
        return 
    }
    #$nombresEncontrados = New-Object 'System.Collections.Generic.HashSet[string]'
    $idsEncontrados = New-Object 'System.Collections.Generic.HashSet[int]'
    Get-Content "cache.ej5" | ConvertFrom-Json | ForEach-Object {
        $encontro = $false
        # foreach($nombre in $nombres.Value){
        #     if ($_.name -match $nombre){
        #         $nombresEncontrados.Add($nombre) > $null #para que no imprima True o False cuando agrega
        #         $encontro = $True
        #     }

        # }
        foreach($id in $ids.Value){
            if ($_.id -eq $id){
                $idsEncontrados.Add($id) > $null
                $encontro = $True
            }

        }
        if($encontro){
            $global:Resultados += $_
        }
    }
    #$nombres.Value = $nombres.Value | Where-Object {$_ -notin $nombresEncontrados}
    $ids.Value = $ids.Value | Where-Object {$_ -notin $idsEncontrados}
}
$global:Resultados = @()
buscarEnArchivo ([ref]$id) #en el archivo solo busca por id, no busca por nombres, mando referencia de id asi la funcion elimina los ids que fueron encontrados en el archiov


petitcionPorId $id
petitcionPorNombre $nombre

$Resultados =  $Resultados | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 }  #elimina posibles personajes duplicados que pudieron venir de la red y archivo, basandose en el id, los agrupa y me quedo con el primer elemento de ese grupo+
$Resultados | imprimirObjeto

$todosLosPersonajes = @() 
if (Test-Path "cache.ej5"){
    $elementosAlmacenados = Get-Content "cache.ej5" | ConvertFrom-Json
    $todosLosPersonajes = $($elementosAlmacenados;$Resultados) | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 } #concatena los arrays de objetos del archivo con los obtenidos por web y luego lo convierte a json.
}else{
    $todosLosPersonajes = $Resultados 
}

$todosLosPersonajes | ConvertTo-Json > "cache.ej5" 




