dir=../../TextosEjercicio3
archivos=`ls -d $dir/*`
extension="dat"
separador="e"
omitir="def, uji, lojo"


#pasar todo a minuscula (asi Linux y linux es la misma palabra)
#remover caracteres especiales (.,!? etc), salvo el delimitador 
awk -F"$separador" -v extension="$extension" -v omitir="$omitir" '
BEGIN {
    archivoRegex = extension "$" #el simbolo $ al final de la regex indica que quiero que la cadena termine con lo que le dije antes
    #por ejemplo para la extension de un archivo seria tipo txt$, porque quiero quedarme con los archivos que terminen txt
    conteoArchivos = 0
    cantTotalPalabras = 0
}
match(FILENAME, archivoRegex){
    if (archivoAnterior != FILENAME)
        conteoArchivos++

    for(i=1; i<=NF; i++){
        gsub(/[^A-Za-z0-9]/,"",$i) #elimina todo lo que no sea letra o numero
        $i = tolower($i) #pasa todo a minuscula
        conteoLongitudPalabras[length($i)]++
        conteoDeOcurrenciasDePalabras[$i]++
        cantTotalPalabras++
        for ( j = 1; j<=length($i);j++ ){
            char = substr($i,j,1)
            conteoCaracteres[char]++
        }
    }
    archivoAnterior = FILENAME
}
END{
    for (longitud in conteoLongitudPalabras){
        print "Palabras de " longitud " caracteres: " conteoLongitudPalabras[longitud]
    }
    maxOcurrenciaDePalabras = 0
    for (ocurrencia in conteoDeOcurrenciasDePalabras){ #obtengo el maximo de ocurrencias de una palabra
        if (conteoDeOcurrenciasDePalabras[ocurrencia]>maxOcurrenciaDePalabras)
            maxOcurrenciaDePalabras = conteoDeOcurrenciasDePalabras[ocurrencia]
    }
    for(ocurrencia in conteoDeOcurrenciasDePalabras){ #cargo array con las palabras con mas ocurrencias
        if (conteoDeOcurrenciasDePalabras[ocurrencia] == maxOcurrenciaDePalabras){
            conteoMaximoDePalabras[ocurrencia] = 1 #las claves del array asociativo son las palabras que mas aparecieron
        }
    }
    print ""
    print "Palabra/s que mas aparecio/eron, (" maxOcurrenciaDePalabras ") veces"
    for (i in conteoMaximoDePalabras){
        print i
    }
    print ""
    print "Cantidad total de palabras: " cantTotalPalabras
    print ""

    if (conteoArchivos > 0)
        print "Promedio de palabras por archivo: " cantTotalPalabras/conteoArchivos
    else
        print "Promedio de palabras por archivo: 0" 

    maxOcurrenciaDeCaracteres = 0
    for (ocurrencia in conteoCaracteres){ #obtengo el maximo de ocurrencias de un caracter
        if (conteoCaracteres[ocurrencia]>maxOcurrenciaDeCaracteres)
            maxOcurrenciaDeCaracteres = conteoCaracteres[ocurrencia]
    }
    for(ocurrencia in conteoCaracteres){ #cargo array con los caracteres con mas ocurrencias
        if (conteoCaracteres[ocurrencia] == maxOcurrenciaDeCaracteres){
            conteoMaximoDeCaracteres[ocurrencia] = 1 #las claves del array asociativo son los caracteres que mas aparecieron
        }
    }
    print ""
    print "Caracteres/s que mas aparecio/eron, (" maxOcurrenciaDeCaracteres ") veces"
    for (i in conteoMaximoDeCaracteres){
        print i
    }
    
}
' $archivos