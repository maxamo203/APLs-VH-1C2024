import random
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
    with open(f'{primerCodigoMateria+i}.csv', 'w') as archivoMateria:
        archivoMateria.write('DNI-Alumno,' + ','.join(f'nota-ej-{i}' for i in range(1,cantNotas+1))+'\n')
        for dni in dnisDeMAteria:
            cadenaNotas = str([random.choice(notas) for i in range(cantNotas)]).replace("'",'').replace('[', '').replace(']', '').replace(" ",'')
            archivoMateria.write(f'{dni},{cadenaNotas}\n')
            print(f'{dni},{cadenaNotas} \n')
    
