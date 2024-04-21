Param(
  [Parameter(Mandatory = $True, ParameterSetName = "invocar")]
  [Parameter(Mandatory = $True, ParameterSetName = "matar")]
  [string]$directorio,

  [Parameter(Mandatory = $True, ParameterSetName = "invocar")]
  [System.IO.DirectoryInfo]$salida,

  [Parameter(Mandatory = $false, ParameterSetName = "invocar")]
  [string]$patron,

  [Parameter(Mandatory = $True, ParameterSetName = "matar")]
  [switch]$kill
)

try {
  $directorio = Resolve-Path $directorio -ErrorAction Stop #convierto el direcotrio a analizar en ruta absoluta, asi es siempre el mismo
  #el ErrorAction Stop es para que en caso de error salte al catch, por defecto no lo hace
}
catch {
  Write-Error "No se pudo convertir $directorio a una ruta absoluta"
  exit 2
}
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
    Write-Error "Ya se esta monitoreando $directoriofunc, si quieres frenarlo indica el parametro -kill"
    exit 1
  }
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

$bloque = {
  param($directorio, $salida, $patron)
  function fechaFormateada{
    return Get-Date -Format "yyyyMMdd-HHmmss"
  }
  function main {
    param($directorio, $salida, $patron)

    #Deja registrado en el archivo que se esta monitoreando el directorio, con el PID correspondiente
    try {
      Write-Output "$($PID) $($directorio)" >> "/tmp/Ejercicio4/running.ej4"

      $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
        Path                  = $directorio
        Filter                = "*"
        IncludeSubdirectories = $true
        NotifyFilter          = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite 
      }
  
      . {
        Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action {
          $fecha = fechaFormateada
          $coincidenciasPatron = Select-String -Path $event.SourceEventArgs.FullPath -Pattern $patron
          if ($coincidenciasPatron){
            Compress-Archive -Path $event.SourceEventArgs.FullPath -DestinationPath "$salida/$fecha.zip" -CompressionLevel Fastest
            Write-Output "$fecha--$($event.SourceEventArgs.FullPath)--modificado--se realizo back up" >> "/tmp/Ejercicio4/ej4.log"
          }
          else{
            Write-Output "$fecha--$($event.SourceEventArgs.FullPath)--modificado--no se realizo back up" >> "/tmp/Ejercicio4/ej4.log"
          }
        }
        Register-ObjectEvent -InputObject $watcher -EventName Created  -Action {
          $fecha = fechaFormateada
          Write-Output "$fecha--$($event.SourceEventArgs.FullPath)--creado" >> "/tmp/Ejercicio4/ej4.log"
        } 
      }
    
      # monitoring starts now:
      $watcher.EnableRaisingEvents = $true
      do {
        # Wait-Event waits for a second and stays responsive to events
        # Start-Sleep in contrast would NOT work and ignore incoming events
        Wait-Event -Timeout 1
        
            
      } while ($true)
    }catch{
      Write-Error $Errors[0] >> ./errores.txt
    }
    
    
  }

  
  main -directorio $directorio -salida $salida -patron $patron
}


if ($PSCmdlet.ParameterSetName -eq "invocar") {
  #si los parametros que se pasaron, son los de invocar ...
  comprobarDirectorioMonitoreado $directorio
  Start-Job -ScriptBlock $bloque -ArgumentList $directorio, $salida, $patron
}
else {
  #son los parametros para matar un proceso
  dejarMonitorizar $directorio
}