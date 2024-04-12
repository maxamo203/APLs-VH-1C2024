#! /bin/bash

dir="../../NotasEjercicio1"
salida="./salida2.json"
archivos=`ls -d $dir/*`
awk -F',' '
$1 ~ /[0-9]+/ { 
    ponderacion = 10/(NF-1)
    nota = 0
    for( i=2;i<=NF; i++){
        if($i == "b")
            nota += ponderacion
        if($i == "r")
            nota += (ponderacion/2)    
    }


    n = split(FILENAME, path, "/")
    split(path[n], name, ".")
    alumnos[$1] = alumnos[$1] "   {\"materia\":" name[1] ", \"nota\":" int(nota) "},\n"
}
END {
    print "{\"notas\": ["
    for (i in alumnos){
        print " {"
        print "  \"dni\": \""i"\","
        print "  \"notas\": ["
        alumnoLimpio = substr(alumnos[i],1,length(alumnos[i])-2)
        print  alumnoLimpio
        contador++
        if(contador == length(alumnos))
            print "  ]}"
        else
            print "  ]},"
    }

    print "] }"
}' $archivos > $salida
echo "Fin"