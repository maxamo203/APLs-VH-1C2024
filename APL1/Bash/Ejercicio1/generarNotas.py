import sys
import os
import random

# Obtener el directorio de destino de los argumentos de línea de comandos
if len(sys.argv) < 2:
    print("Usage: python script.py <directory>")
    sys.exit(1)

directorio_destino = sys.argv[1]

# Verificar si el directorio existe, si no, crearlo
if not os.path.exists(directorio_destino):
    os.makedirs(directorio_destino)

cantAlumnosTotales = 200
maxAlumnPorMateria = 100
cantMaterias = 15
primerCodigoMateria = 1120
notas = ['b','r','m']
alumnos = list(set([random.randint(20000000,50000000) for i in range(cantAlumnosTotales)])) #asi no hay dni repetidos
for i in range(cantMaterias):
    cantAlumnosEnMateria = random.randint(10, len(alumnos) if len(alumnos)<maxAlumnPorMateria else maxAlumnPorMateria )
    cantNotas = random.randint(1,15)
    dnisDeMAteria = random.sample(alumnos,cantAlumnosEnMateria)
    with open(os.path.join(directorio_destino, f'{primerCodigoMateria+i}.csv'), 'w') as archivoMateria:
        archivoMateria.write('DNI-Alumno,' + ','.join(f'nota-ej-{i}' for i in range(1,cantNotas+1))+'\n')
        for dni in dnisDeMAteria:
            cadenaNotas = str([random.choice(notas) for i in range(cantNotas)]).replace("'",'').replace('[', '').replace(']', '').replace(" ",'')
            archivoMateria.write(f'{dni},{cadenaNotas}\n')

