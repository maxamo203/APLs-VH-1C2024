<#
  .SYNOPSIS
  Este es un Script que monitoriza directorios en segundo plano
  .DESCRIPTION
  Este es un script que monitoriza directorios en segundo plano, mediante Jobs, impidiendo llamar el script dos veces para el mismo directorio. No monitorea subdirectorios, estos deben ser indicados como otro directorio aparte. Ademas, realiza backups de los archivos que contengan un patron que debe ser indicado por el usuario. Estos backups se crean en el directorio indicado en -salida. Solo registra creaciones y modificaciones de archivos
  .EXAMPLE
  ./Ejercicio4.ps1 -directorio ../Ejercicio2/carpetaprueba/ -salida ../Ejercicio3 -patron bkp
  .EXAMPLE
  ./Ejercicio4.ps1 -directorio ../Ejercicio2/carpetaprueba/ -kill
  .EXAMPLE
  ./Ejercicio4.ps1 -consultar
  .PARAMETER directorio
  Indica la carpeta que sera monitorizada. Analiza creaciones y modificaciones de archivos
  .PARAMETER salida
  Indica la carpeta donde se alojaran los archivos comprimidos que contienen los backups de los archivos que cumplen que tienen el patron
  .PARAMETER patron
  Si el patron se encuentra en el archivo, se realizara un backup de este, en formato .zip, en -salida
  .PARAMETER kill
  Indicando ademas -directorio, indica que se quiere finalizar la monitorizacion de un directorio
  .PARAMETER consultar
  Muestra los directorios que se estan monitoreando en ese momento
#>
Param(
  [Parameter(Mandatory = $True, ParameterSetName = "invocar")]
  [Parameter(Mandatory = $True, ParameterSetName = "matar")]
  [string]$directorio, #lo uso como string porque sino me da problemas cuando quiero convertirlo a ruta absoluta

  [Parameter(Mandatory = $True, ParameterSetName = "invocar")]
  [System.IO.DirectoryInfo]$salida,

  [Parameter(Mandatory = $true, ParameterSetName = "invocar")]
  [string]$patron,

  [Parameter(Mandatory = $True, ParameterSetName = "matar")]
  [switch]$kill,

  [Parameter(Mandatory = $True, ParameterSetName = "consultar")]
  [switch]$consultar
)


function comprobarDirectorioMonitoreado {
  param(
    [System.IO.DirectoryInfo]$directoriofunc
  )
  if (-not (Test-Path "/tmp/Ejercicio4/running.ej4")) {
    mkdir "/tmp/Ejercicio4"
    New-Item -Path "/tmp/Ejercicio4/running.ej4" -ItemType File
  }
  #$procesosExistentes = Get-Content "/tmp/Ejercicio4/running.ej4" | ForEach-Object
  $coincidencias = Select-String -Path "/tmp/Ejercicio4/running.ej4" -Pattern $directoriofunc
  if ($coincidencias) {
    Write-Error "Ya se esta monitoreando $directoriofunc o un subdirectorio de esta, si quieres frenarlo indica el parametro -kill. Puedes ver los directorios monitoreandose con -consultar"
    exit 1
  }
}
function mostrarDirectoriosMonitoreandose{
  if (-not (Test-Path -Path "/tmp/Ejercicio4/running.ej4")){
    Write-Output "No hay directorios monitoreandose"
    exit 0
  }

  $procesosCorriendo = (Get-Content "/tmp/Ejercicio4/running.ej4").Split(' ', 2) #guarda PID- Directorio- PID-Directorio... #el 2 es para que solo divida hasta la aparicion del primer espacio (el que divide PID de directorio) asi no separa por espacios que podria tener un directorio++
  if ($procesosCorriendo.Count -eq 0){
    Write-Output "No hay directorios monitoreandose"
    exit 0
  }
  
  Write-Output "Directorios Monitoreandose:"
  Write-Output "-------------------"
  for($i=1; $i -le $procesosCorriendo.Count; $i+=2){
    Write-Output "$($procesosCorriendo[$i])"
  }
  Write-Output "-------------------"
}
function dejarMonitorizar {
  param ($directorio)
  #ir al running ej4
  #leer el PID
  #kill del PID
  #borrar el registro de esa linea
  if (-not (Test-Path "/tmp/Ejercicio4/running.ej4")) {
    Write-Error "No hay ningun directorio monitoreandose"
    exit 4
  }

  $coincidencias = Select-String -Path "/tmp/Ejercicio4/running.ej4" -Pattern $directorio #trae las lineas donde se indica el directorio (deberia ser solo una)
  if (-not $coincidencias) {
    Write-Error "No se esta monitoreando $directorio, si quieres monitorearlo indica el parametro -salida y -patron"
    exit 3
  }
  #ejemplo de coincidencia:
  #running.ej4:2:93888 /home/maximobosch/APLs-VH-1C2024/APL1/PowerShell/Ejercicio2
  $pidABorrar = $coincidencias[0].ToString().Split()[0].Split(":")[2]
  Stop-Process $pidABorrar

  $lineaABorrar = $coincidencias[0].ToString().Split()[0].Split(":")[1]
  $lineas = Get-Content "/tmp/Ejercicio4/running.ej4"
  if ($lineas.Count -eq 1) {
    #si solo queda un proceso, borra el archivo directamente
    Remove-Item -Path "/tmp/Ejercicio4/running.ej4" 
  }
  else {

    Clear-Content "/tmp/Ejercicio4/running.ej4" #borra todas las lineas para escribirlas devuelta, sin la que mate recien
    for ($i = 0; $i -lt $lineas.Count; $i++) {
      if ($i -eq $lineaABorrar - 1) {
        continue
      }
      Write-Output $lineas[$i] >> "/tmp/Ejercicio4/running.ej4"
    }
  }
  Write-Host "Ya no se esta monitoreando el directorio $directorio" -ForegroundColor Green
}

function verificarIntegridadProcesosCorriendo{
  if (-not (Test-Path -Path "/tmp/Ejercicio4/running.ej4")){
    return 
  }
  $procesosGuardados = (Get-Content "/tmp/Ejercicio4/running.ej4") -split "\r?\n" #para que separe por lineas
  $procesosGuardados = [System.Collections.ArrayList]$procesosGuardados
  $lineasABorrar = @()
  for($i = 0; $i -lt $procesosGuardados.Count; $i++) { #busca procesos que esten en el archivo pero que no se esten ejecutando (causado por un cierre inesperado del archivo)
    $pidLeido = $procesosGuardados[$i].Split()[0]
    $procesoCorriendo = Get-Process | Where-Object Id -eq $pidLeido
    if (-not $procesoCorriendo){
      $lineasABorrar += $i
      Write-Warning "El proceso de PID: $pidLeido no se encontraba corriendo, pero estaba en el archivo, eliminando del archivo..."
    }
  }
  $lineasABorrar = $lineasABorrar | Sort-Object -Descending #para que borre indices de atras para adelante y no queden indices corridos
  foreach ($linea in $lineasABorrar){ #borra las lineas de los procesos
    $procesosGuardados.RemoveAt($linea)
  }
  Write-Output $procesosGuardados > "/tmp/Ejercicio4/running.ej4"
}

$bloque = {
  param($directorio, $salida, $patron)
  function fechaFormateada{
    return Get-Date -Format "yyyyMMdd-HHmmss"
  }
  function main {
    param($directorio, $salida, $patron)

    #Deja registrado en el archivo que se esta monitoreando el directorio, con el PID correspondiente
    try {
      

      $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
        Path                  = $directorio
        Filter                = "*"
        IncludeSubdirectories = $false
        NotifyFilter          = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 

      }
  
      $accion = {
        $fecha = fechaFormateada
        $coincidenciasPatron = Select-String -Path $event.SourceEventArgs.FullPath -Pattern $patron
        if ($coincidenciasPatron){
          Start-Job -ScriptBlock { #no se porqué si la compresion lo hago en otro subproceso anda bien, si lo hago sin subproceso, cuando comprime un archivo deja de monitorear cambios (con o sin backup)
            param($path, $destination)
            Compress-Archive -Path $path -DestinationPath $destination -CompressionLevel "Fastest"
        } -ArgumentList $event.SourceEventArgs.FullPath, "$salida/$fecha.zip"

          Write-Output "$fecha--$($event.SourceEventArgs.FullPath)--$($event.SourceEventArgs.ChangeType)--realizo back up" >> "/tmp/Ejercicio4/ej4.log"
        }
        else{
          Write-Output "$fecha--$($event.SourceEventArgs.FullPath)--$($event.SourceEventArgs.ChangeType)--no se realizo back up" >> "/tmp/Ejercicio4/ej4.log"
        }
      }
      . {
        Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $accion 
        Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $accion 
      }
      
      Write-Output "$($PID) $($directorio)" >> "/tmp/Ejercicio4/running.ej4"
      # monitoring starts now:
      $watcher.EnableRaisingEvents = $true
      do {
        # Wait-Event waits for a second and stays responsive to events
        # Start-Sleep in contrast would NOT work and ignore incoming events
        Wait-Event -Timeout 1
        
            
      } while ($true)
    }finally{
      Write-Output "chauuuu" >> ./errores.txt
    }
    
    
  }

  
  main -directorio $directorio -salida $salida -patron $patron
}

verificarIntegridadProcesosCorriendo

if ($PSCmdlet.ParameterSetName -ne "consultar"){
  try {
    $directorio = Resolve-Path $directorio -ErrorAction Stop #convierto el direcotrio a analizar en ruta absoluta, asi es siempre el mismo
    #el ErrorAction Stop es para que en caso de error salte al catch, por defecto no lo hace
  }
  catch {
    Write-Error "No se pudo convertir $directorio a una ruta absoluta"
    exit 2
  }
}

if ($PSCmdlet.ParameterSetName -eq "invocar") {
  #si los parametros que se pasaron, son los de invocar ...
  comprobarDirectorioMonitoreado $directorio
  Start-Job -ScriptBlock $bloque -ArgumentList $directorio, $salida, $patron
}
elseif ($PSCmdlet.ParameterSetName -eq "matar") {
  #son los parametros para matar un proceso
  dejarMonitorizar $directorio
}
elseif ($PSCmdlet.ParameterSetName -eq "consultar"){
  mostrarDirectoriosMonitoreandose
}