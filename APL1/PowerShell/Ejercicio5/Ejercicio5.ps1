param(

    [Parameter(Mandatory=$true, ParameterSetName="id")]
    [Parameter(Mandatory=$true, ParameterSetName="idnombre")]
    [int[]]$id,
    [Parameter(Mandatory=$true, ParameterSetName="nombre")]
    [Parameter(Mandatory=$true, ParameterSetName="idnombre")]
    [string[]]$nombre

)
function busquedaBinariaMultiple{
    param(
        [Object[]]$source,
        [int[]]$targets
    )
    $inf = 0
    $sup = $source.Count-1 #topes inclusivos
    $targetsEncontrados = @()
    $actual = 0 #se mueve entre todos los personajes
    $conteo = 0 #sirve para ver cuantas iteraciones se hicieron en total
    $targetActual = 0 #el target (id) que esta buscadno
    $conteoTargets = 0 #cuantos targets lleva analizados
    while ($conteoTargets -lt $targets.Count){
        $base = $inf
        $top = $sup
        $flag = $false
        $targetActual = $conteoTargets % 2 -eq 0? $conteoTargets/2 : $targets.Count-1-($conteoTargets-1)/2 #para que el id que se busque de la forma 0,n-1,1,n-2,2,n-3, etc
        Write-Warning "buscando $($targets[$targetActual])... ($conteoTargets)"
        while ($base -le $top){
            [int]$actual = ($top+$base) / 2
            $conteo++
            Write-Warning "salida $base $actual $top"
            if ($source[$actual].id -eq $targets[$targetActual]){
                $global:Resultados += $source[$actual]
                $targetsEncontrados += $targets[$targetActual]
                $flag = $true
                break
            }
            elseif($source[$actual].id -lt $targets[$targetActual]){
                $base = $actual+1
            }
            else{
                $top = $actual-1
            }
        }

        if($conteoTargets % 2 -eq 0){
            if($flag){
                $inf = $actual + 1
            }else{
                $inf = $actual
            }
        }
        else{
            if($flag){
                $sup = $actual - 1
            }else{
                $sup = $actual
            }
        }
        $conteoTargets++
    }
    Write-Warning "Iteraciones $conteo, Total $($source.Count)"
    return $targetsEncontrados

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
}
function petitcionPorNombre{
    param ([string[]]$nombres)
    if($nombres.Count -eq 0){
        return
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
    
}
function getIds{
    param([string[]]$nombres)
    if ($global:IndicePersonajes.Count -eq 0){
        return
    }
    $asignaciones = @{}
    foreach($nombre in $nombres){
        $id = $global:IndicePersonajes.($nombre) #la comparacion ya es insensitive. (si el nombre esta en el indice)
        if ($id){
            
            $asignaciones[[string]$id] = $nombre #casteo el $id xq estuve 2hs viendo porque cunado queria acceder a un id especifico no me tiraba nada
        }
        
    }
    return $asignaciones
}
function calcularIndices {
    param(
        [Object[]]$personajes
    )
    $tabla = [PSCustomObject]@{}
    foreach ($personaje in $personajes) {
        # $nombre = $personaje.name
        # $tabla.$($nombre) = $personaje.id
        if(-not $tabla.($personaje.name)){ #para que no sobreescriba la propiedad, en tal caso se queda con la primer opcion
            $tabla |  Add-Member -MemberType NoteProperty -Name $personaje.name -Value $personaje.id
        }
    }
    return $tabla
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
    $idsDeNombres = getIds $nombres.Value #busque el id del nombre en el indice, devuelve {id: nombre} 
    #Write-Output "$($idsDeNombres.Keys) $($idsDeNombres.Values)"
    
    $idsEncontrados = busquedaBinariaMultiple $global:PersonajesArchivos $ids.Value
    Write-Warning "---------------------------"
    $idnombresEncontrados = busquedaBinariaMultiple $global:PersonajesArchivos ($idsDeNombres.Keys | Sort-Object)
    
    #$nombres.Value = $nombres.Value | Where-Object {$_ -notin $nombresEncontrados}
    $ids.Value = $ids.Value | Where-Object {$_ -notin $idsEncontrados} #elimina los ids que se encontraron en el archivo para que no los busque en la API
    $nombresEncontrados = $idnombresEncontrados | ForEach-Object {$idsDeNombres[[string]$_]}
    
    $nombres.Value = $nombres.Value | Where-Object {$_ -notin $nombresEncontrados}
    
}

$global:Resultados = @()
$global:PersonajesArchivos = @()
$global:IndicePersonajes = @()

if (Test-Path "./cache.ej5"){
    $global:PersonajesArchivos = Get-Content "cache.ej5" | ConvertFrom-Json
}
if (Test-Path "./indice.ej5"){
    $global:IndicePersonajes = Get-Content "indice.ej5" | ConvertFrom-Json
}

$id = $id | Group-Object |ForEach-Object { $_.Group | Select-Object -First 1 } #ordena ids para usarlos ordenados en busqueda binaria y elimina duplicados

buscarEnArchivo ([ref]$id) ([ref]$nombre) #en el archivo solo busca por id, no busca por nombres, mando referencia de id asi la funcion elimina los ids que fueron encontrados en el archiov

petitcionPorId $id
petitcionPorNombre $nombre

if($Resultados.Count -eq 0){
    exit 0
}

$Resultados =  $Resultados | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 }  #elimina posibles personajes duplicados que pudieron venir de la red y archivo, basandose en el id, los agrupa y me quedo con el primer elemento de ese grupo
$Resultados | imprimirObjeto

$todosLosPersonajes = @() 
if ($global:PersonajesArchivos.Count -ne 0){
    $todosLosPersonajes = $($global:PersonajesArchivos;$Resultados) | Group-Object -Property id | ForEach-Object { $_.Group | Select-Object -First 1 } #concatena los arrays de objetos del archivo con los obtenidos por web y luego lo convierte a json.
}else{
    $todosLosPersonajes = $Resultados 
}


(calcularIndices $todosLosPersonajes)  | ConvertTo-Json > "indice.ej5"
$todosLosPersonajes | ConvertTo-Json > "cache.ej5" 




