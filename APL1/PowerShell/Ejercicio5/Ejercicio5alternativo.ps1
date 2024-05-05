<#
.SYNOPSIS
Este script interactua con la api de rickandmorty, permitiendo buscar por id o por nombre de personaje
.DESCRIPTION
Este script interactua con la api de rickandmorty, permitiendo buscar por id o por nombre de personaje, y ademas cachea los resultados obtenidos para que una futura busqueda del mismo personaje no demore tanto tiempo.
.EXAMPLE
./Ejercicio5.ps1 -id 3,6,9
.EXAMPLE
./Ejercicio5.ps1 -nombre "Rick Sanchez", "Morty Smith"
.EXAMPLE 
./Ejercicio5.ps1 -nombre "Rick Sanchez", "Morty Smith" -id 3,6,9
.NOTES
Si la busqueda es por nombre, solo traera un personaje del cache si la coincidencia es exacta (case insensitive)
./Ejercicio5.ps1 -nombre "Rick Sanchez" --> lo va a buscar en cache
./Ejercicio5.ps1 -nombre "Rick" --> no lo va a buscar en cache y traera todos los resultados de la api
En el caso que varios personajes tengan exactamente el mismo nombre, en el indice se guardara el id del que haya venido primero
#>
param(

    [Parameter(Mandatory=$true, ParameterSetName="id")]
    [Parameter(Mandatory=$true, ParameterSetName="idnombre")]
    [int[]]$id,
    [Parameter(Mandatory=$true, ParameterSetName="nombre")]
    [Parameter(Mandatory=$true, ParameterSetName="idnombre")]
    [string[]]$nombre


)

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
        return $false
    }
    
    try{ 
        $res = Invoke-RestMethod -Uri "https://rickandmortyapi.com/api/character/$($id -join ",")" | parsearObjeto
        $global:Resultados += $res

        #miro si algun id no trajo personaje
        $idsPersonajes = $res | ForEach-Object {$_.id}
        $id | Where-Object {$idsPersonajes -notcontains $_} | ForEach-Object{
            Write-Warning "No se encontro el ID $_"
        }
    
    }
    catch{
       # Accede al objeto de respuesta de la excepción
       $responseError = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Warning "$($responseError.error): $id"
    }
    return $true
}
function petitcionPorNombre{
    param ([string[]]$nombres)
    if($nombres.Count -eq 0){
        return $false
    }
    foreach($nombre in $nombres){
        try{ 
            $res = (Invoke-RestMethod -Uri "https://rickandmortyapi.com/api/character/?name=$nombre").results | parsearObjeto 
            
            $global:Resultados += $res
        }
        catch{
           # Accede al objeto de respuesta de la excepción
           $responseError = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Warning "$($responseError.error): No existe un $nombre"
        }

    }
    return $true
}
function buscarEnArchivo{
    param(
        [Parameter(Mandatory)]
        [ref]$ids,

        [Parameter(Mandatory)]
        [ref]$nombres
    )
    
    if($global:PersonajesArchivos.Count -eq 0){
        return 
    }
    #$idsDeNombres = getIds $nombres.Value #busque el id del nombre en el indice, devuelve {id: nombre} 
    #Write-Output "$($idsDeNombres.Keys) $($idsDeNombres.Values)"
    
    $idsEncontrados = $global:PersonajesArchivos | Where-Object {$_.id -in $ids.Value}
    $global:Resultados += $idsEncontrados
    Write-Warning "---------------------------"
    $nombresEncontrados = $global:PersonajesArchivos | Where-Object {$_.name -in $nombres.Value}
    $global:Resultados += $nombresEncontrados
    $idsSolos = $idsEncontrados  | Select-Object -ExpandProperty id 
    $nombresSolos = $nombresEncontrados  | Select-Object -ExpandProperty name 
    $ids.Value = $ids.Value | Where-Object {$_ -notin $idsSolos} #elimina los ids que se encontraron en el archivo para que no los busque en la API
    
    $nombres.Value = $nombres.Value | Where-Object {$_ -notin $nombresSolos}
    Write-Output "Nombres a la api:"
    Write-Output $nombres.Value
}
$ini = Get-Date
$global:Resultados = @()
$global:PersonajesArchivos = @()
#$global:IndicePersonajes = @()

if (Test-Path "./cache.ej5"){
    $global:PersonajesArchivos = Get-Content "cache.ej5" | ConvertFrom-Json
}
# if (Test-Path "./indice.ej5"){
#     $global:IndicePersonajes = Get-Content "indice.ej5" | ConvertFrom-Json
# }

$id = $id | Group-Object |ForEach-Object { $_.Group | Select-Object -First 1 } #ordena ids para usarlos ordenados en busqueda binaria y elimina duplicados

buscarEnArchivo ([ref]$id) ([ref]$nombre) #en el archivo solo busca por id, no busca por nombres, mando referencia de id asi la funcion elimina los ids que fueron encontrados en el archiov

$resId = petitcionPorId $id
$resNombre = petitcionPorNombre $nombre

if($Resultados.Count -eq 0){
    exit 0
}

$Resultados =  $Resultados | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 }  #elimina posibles personajes duplicados que pudieron venir de la red y archivo, basandose en el id, los agrupa y me quedo con el primer elemento de ese grupo
$Resultados | imprimirObjeto

$mid = Get-Date
if ($resId -eq $true -or $resNombre -eq $true){ #que actualize el cache y los indices si hubo alguna peticion a la api
    $todosLosPersonajes = @() 
    if ($global:PersonajesArchivos.Count -ne 0){
        $todosLosPersonajes = $($global:PersonajesArchivos;$Resultados) | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 } #concatena los arrays de objetos del archivo con los obtenidos por web y luego lo convierte a json.
    }else{
        $todosLosPersonajes = $Resultados 
    }
    
    
    #(calcularIndices $todosLosPersonajes)  | ConvertTo-Json > "indice.ej5"
    $todosLosPersonajes | ConvertTo-Json > "cache.ej5" 
}else{
    Write-Warning "somo lisbres"
}

$fin = Get-Date
$durMid = $mid - $ini
$durFIn = $fin - $ini
Write-Output "Tiempo hasta imprimir $($durMid.TotalMilliseconds)`nTiempo hasta temrinar $($durFIn.TotalMilliseconds)"



