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
#INTEGRANTES:
#BOSCH, MAXIMO AUGUSTO
#MARTINEZ CANNELLA, IÃ±AKI
#MATELLAN, GONZALO FACUNDO
#VALLEJOS, FRANCO NICOLAS
#ZABALGOITIA, AGUSTÍN
param(
    [Parameter(Mandatory=$true, ParameterSetName="id")]
    [Parameter(Mandatory=$true, ParameterSetName="idnombre")]
    [int[]]$id,
    [Parameter(Mandatory=$true, ParameterSetName="nombre")]
    [Parameter(Mandatory=$true, ParameterSetName="idnombre")] #con este juego de parametersetName's me aseguro de que me va a dejar pasar solo id o solo nombre o los dos, pero no ninguno
    [string[]]$nombre
)

function parsearObjeto{ #convierte el objeto que trae el json de la peticion al formato necesario
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
        Write-Warning "$($responseError.error): No existe el id $id"
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
    
    $idsEncontrados = $global:PersonajesArchivos | Where-Object {$_.id -in $ids.Value}
    $global:Resultados += $idsEncontrados
    $nombresEncontrados = $global:PersonajesArchivos | Where-Object {$_.name -in $nombres.Value}
    $global:Resultados += $nombresEncontrados

    $idsSolos = $idsEncontrados  | Select-Object -ExpandProperty id 
    $nombresSolos = $nombresEncontrados  | Select-Object -ExpandProperty name #deja un array solo con los nombres

    $ids.Value = $ids.Value | Where-Object {$_ -notin $idsSolos} #elimina los ids que se encontraron en el archivo para que no los busque en la API
    $nombres.Value = $nombres.Value | Where-Object {$_ -notin $nombresSolos} #elimina los nombres que se encontraron en el archivo para que no los busque en la API
    
}
#$ini = Get-Date
$global:Resultados = @()
$global:PersonajesArchivos = @()

if (Test-Path "./cache.ej5"){
    $global:PersonajesArchivos = Get-Content "cache.ej5" | ConvertFrom-Json
}

buscarEnArchivo ([ref]$id) ([ref]$nombre) # mando referencia de id y nombre asi la funcion elimina los ids y nombres que fueron encontrados en el archiov
$resId = petitcionPorId $id
$resNombre = petitcionPorNombre $nombre

if($Resultados.Count -eq 0){ #si no trajo ningun personaje temrina el script
    exit 0
}

$Resultados =  $Resultados | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 }  #elimina posibles personajes duplicados que pudieron venir de la red y archivo, basandose en el id, los agrupa y me quedo con el primer elemento de ese grupo
$Resultados | imprimirObjeto

#$mid = Get-Date
if ($resId -eq $true -or $resNombre -eq $true){ #que actualize el cache si hubo alguna peticion a la api
    $todosLosPersonajes = @() 
    if ($global:PersonajesArchivos.Count -ne 0){
        $todosLosPersonajes = $($global:PersonajesArchivos;$Resultados) | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 } #concatena los arrays de objetos del archivo con los obtenidos por web y luego lo convierte a json.
    }else{
        $todosLosPersonajes = $Resultados 
    }
    
    $todosLosPersonajes | ConvertTo-Json > "cache.ej5" 
}

# $fin = Get-Date
# $durMid = $mid - $ini
# $durFIn = $fin - $ini
# Write-Output "Tiempo hasta imprimir $($durMid.TotalMilliseconds)`nTiempo hasta temrinar $($durFIn.TotalMilliseconds)"



