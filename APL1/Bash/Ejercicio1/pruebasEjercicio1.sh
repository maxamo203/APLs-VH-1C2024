#!/bin/bash

#TODO: hacer que se puedan ejecutar las pruebas de manera individual

#Este script sirve para probar el correcto funcionamiento del Ejercicio1.sh
#Se probarán todos los casos que puedan ocurrir al ejecutar el script.

#Para comprobar que el ejercicio está tratando con los errores adecuadamente
#se utilizan distintos números de salida.

#Configuración inicial para facilitar la lectura de las pruebas
G="\e[32m"	#Color verde
Y="\e[33m"	#Color amarillo
BY="\e[1;33m"	#Color amarillo claro
R="\e[31m"	#Color rojo
W="\e[0m"	#Color blanco

#Función para mostrar por pantalla si la prueba tuvo éxito o no
function mostrarResultado () {
	if [[ $1 == $2 ]]; then
		echo -e "${G} --- Éxito --- ${W}"
	else
		echo -e "${R} --- Fallo --- ${W}"
	fi
}

#Función para eliminar archivos temporales
function limpiarTmp () {
	rm -r /tmp/pruebasEjercicio1
}

#Trap para asegurarse de eliminar todos los archivos y directorios creados durante la ejecución del script de pruebas
#trap limpiarTmp SIGINT SIGTERM EXIT

#Comienzo de las pruebas

echo -e "${Y}Prueba 1: No se le pasan parámetros"
echo -e "resultado esperado: Error por no indicar origen"
echo -e "${BY}EJECUTANDO: ./Ejercicio1.sh${W}"
./Ejercicio1.sh
mostrarResultado $? 3 #Si salió con un 3 entonces no se indicó el origen
echo ""

echo -e "${Y}Prueba 2.1: Se le pasa el parámetro de directorio (en formato corto) pero sin ruta"
echo -e "Resultado esperado: Error en las opciones"
echo -e "${BY}EJECUTANDO: ./Ejercicio1.sh -d${W}"
./Ejercicio1.sh -d
mostrarResultado $? 4 #Si no se pudieron parsear las opciones devuelve un 4
echo ""

echo -e "${Y}Prueba 2.2: Se le pasa el parámetro de directorio (en formato largo) pero sin ruta"
echo -e "Resultado esperado: Error en las opciones"
echo -e "${BY}EJECUTANDO: ./Ejercicio1.sh --directorio${W}"
./Ejercicio1.sh --directorio
mostrarResultado $? 4
echo ""

#Se le pasa un directorio vacío como parámetro
#Resultado esperado: Informar al usuario de que no hay datos que procesar.
echo -e "${Y}Prueba 3: Se le pasa un directorio vacío como parámetro"
echo -e "Resultado esperado: Informar al usuario de que no hay datos que procesar"
echo -e "${BY}EJECUTANDO: \tmkdir /tmp/pruebasEjercicio1\n\t\t./Ejercicio1.sh -d /tmp/pruebasEjercicio1${W}"
mkdir /tmp/pruebasEjercicio1
./Ejercicio1.sh -d /tmp/pruebasEjercicio1
mostrarResultado $? 0 #Técnicamente no hay error, por lo que debería devolver un 0
echo ""

#Nota, que devuelva un 0 no significa necesariamente que funcione bien
#El enunciado dice claramente que se deben de mostrar los errores de manera amigable al usuario

echo -e "${Y}Prueba 4: Se le pasa un directorio que contenga archivos de distinto formato, pero ninguno de tipo .CSV"
echo -e "Resultado esperado: Informar al usuario de que no hay datos que procesar."
echo -e "${BY}EJECUTANDO: \techo "Hola mundo" > /tmp/pruebasEjercicio1/hola.txt\n\t\thistory > /tmp/pruebasEjercicio1/history.log\n\t\tcp generarNotas.py /tmp/pruebasEjercicio1/${W}"
echo "Hola mundo" > /tmp/pruebasEjercicio1/hola.txt
history > /tmp/pruebasEjercicio1/history.log
cp generarNotas.py /tmp/pruebasEjercicio1/
./Ejercicio1.sh -d /tmp/pruebasEjercicio1
mostrarResultado $? 0 #Igual que la prueba anterior, no debería haber error porque no hay nada que procesar
echo ""

echo -e "${Y}Prueba 5: Se le pasa un directorio que contenga archivos con formato .CSV, y otros archivos de distintos formatos"
echo -e "Resultado esperado: creación exitosa del archivo de salida en la ruta predeterminada"
echo -e "${BY}EJECUTANDO: \tpython3 /tmp/pruebasEjercicio1/generarNotas.py\n\t\t./Ejercicio1.sh -d /tmp/pruebasEjercicio1\n\t\tpython3 -mjson.tool resultado.json 2> /dev/null${W}"
python3 generarNotas.py /tmp/pruebasEjercicio1
./Ejercicio1.sh -d /tmp/pruebasEjercicio1
#En este caso debería de crear un archivo JSON con formato válido
#Para verificar si tiene un formato JSON válido, se puede utilizar python
python3 -mjson.tool resultado.json > /dev/null
mostrarResultado $? 0
echo ""

rm resultado.json #Para evitar conflictos con otras pruebas

echo -e "${Y}Prueba 6: Se le pasa un directorio que solo contenga archivos .CSV"
echo -e "Resultado esperado: Creación exitosa del archivo de salida en la ruta predeterminada"
echo -e "${BY}EJECUTANDO: \tpython3 generarNotas.py /tmp/pruebasEjercicio1/csv\n\t\t./Ejercicio1.sh -d /tmp/pruebasEjercicio1/csv\n\t\tpython3 -mjson.tool resultados.json 2> /dev/null${W}"
python3 generarNotas.py /tmp/pruebasEjercicio1/csv
./Ejercicio1.sh -d /tmp/pruebasEjercicio1/csv
python3 -mjson.tool resultado.json > /dev/null
mostrarResultado $? 0
echo ""

rm resultado.json

echo -e "${Y}Prueba 7: Se le pasa una ruta relativa que solo contenga archivos .CSV"
echo -e "Resultado esperado: Creación exitosa del archivo de salida en la ruta predeterminada"
echo -e "${BY}EJECUTANDO: \t./Ejercicio1.sh -d ~/../../tmp/pruebasEjercicio1/csv\n\t\tpython3 -mjson.tool resultado.json > /dev/null${W}"
./Ejercicio1.sh -d ~/../../tmp/pruebasEjercicio1/csv
python3 -mjson.tool resultado.json > /dev/null
mostrarResultado $? 0
echo ""

rm resultado.json

echo -e "${Y}Prueba 8: Se le pasa una ruta con espacios que colo contenga archivos .CSV"
echo -e "Resultado esperado: Creación exitosa del archivo de salida en la ruta predeterminada"
echo -e "${BY}EJECUTANDO: \tpython3 generarNotas.py /tmp/pruebasEjercicio1/'prueba   8'\n\t\t./Ejercicio1.sh -d /tmp/pruebasEjercicio1/'prueba   8'\n\t\tpython3 -mjson.tool resultado.json > /dev/null${W}"
python3 generarNotas.py "/tmp/pruebasEjercicio1/prueba 8"
./Ejercicio1.sh -d "/tmp/pruebasEjercicio1/prueba 8"
python3 -mjson.tool resultado.json > /dev/null
mostrarResultado $? 0
echo ""

rm resultado.json

echo -e "${Y}Prueba 9.1: Se le pasa el parámetro de salida por pantalla (formato corto) y una dirección válida"
echo -e "Resultado esperado: Salida correcta por pantalla sin la creación de un archivo de resultado"
echo -e "${BY}EJECUTANDO: \t./Ejercicio1.sh -p\n\t\ttest -f resultado.json${W}"
./Ejercicio1.sh -d /tmp/pruebasEjercicio1/csv -p > /tmp/pruebasEjercicio1/prueba9-1.json
[[ ! -f resultado.json && -f /tmp/pruebasEjercicio1/prueba9-1.json ]]
mostrarResultado $? 0
echo ""

echo -e "${Y}Prueba 9.2: Se le pasa el parámetro de salida por pantalla (formato largo) y una dirección válida"
echo -e "Resultado esperado: Salida correcta por pantalla sin la creación de un archivo de resultado"
./Ejercicio1.sh -d /tmp/pruebasEjercicio1/csv --pantalla > /tmp/pruebasEjercicio1/prueba9-2.json
[[ ! -f resultado.json && -f /tmp/pruebasEjercicio1/prueba9-2.json ]]
mostrarResultado $? 0
echo ""

echo -e "${Y}Prueba 10.1: Se le pasa el parámetro de salida por ruta y salida por pantalla (formato corto)"
echo -e "Resultado esperado: Error por parámetros inválidos"
echo -e "${BY}EJECUTANDO: \t./Ejercicio1.sh -s . -p -d /tmp/pruebasEjercicio1/csv${W}"
./Ejercicio1.sh -s . -p -d /tmp/pruebasEjercicio1/csv
mostrarResultado $? 2
echo ""

echo -e "${Y}Prueba 10.2: Se le pasa el parámetro de salida por ruta y salida por pantalla (formato largo)"
echo -e "Resultado esperado: Error por parámetros inválidos"
echo -e "${BY}EJECUTANDO: \t./Ejercicio1.sh --salida . --pantalla --directorio /tmp/pruebasEjercicio1/csv${W}"
./Ejercicio1.sh --salida . --pantalla --directorio /tmp/pruebasEjercicio1/csv
mostrarResultado $? 2
echo ""

echo -e "${Y}Prueba 10.3: Se le pasa el parámetro de salida por pantalla y salida por ruta (formato corto)"
echo -e "Resultado esperado: Error por parámetros inválidos"
echo -e "${BY}EJECUTANDO: \t./Ejercicio1.sh -p -s . -d /tmp/pruebasEjercicio1/csv${W}"
./Ejercicio1.sh -p -s . -d /tmp/pruebasEjercicio1/csv
mostrarResultado $? 2
echo ""

echo -e "${Y}Prueba 10.4: Se le pasa el parámetro de salida por pantalla y salida por ruta (formato largo)"
echo -e "Resultado esperado: Error por parámetros inválidos"
echo -e "${BY}EJECUTANDO: \t./Ejercicio1.sh --salida . --pantalla --directorio /tmp/pruebasEjercicio1/csv${W}"
./Ejercicio1.sh --salida . --pantalla --directorio /tmp/pruebasEjercicio1/csv
mostrarResultado $? 2
echo ""

echo -e "${Y}Prueba 11: Se le pasa una ruta de salida absoluta"
echo -e "Resultado esperado: Creación correcta del archivo de salida"
echo -e "${BY}EJECUTANDO: ./Ejercicio1.sh -s /tmp/pruebasEjercicio1 -d /tmp/pruebasEjercicio1/csv${W}"
./Ejercicio1.sh -s /tmp/pruebasEjercicio1/resultado.json -d /tmp/pruebasEjercicio1/csv
python3 -mjson.tool /tmp/pruebasEjercicio1/resultado.json > /dev/null
mostrarResultado $? 0

echo -e "${Y}Prueba 12: Se le pasa una ruta de salida relativa"
echo -e "Resultado esperado: Creación correcta del archivo de salida"
echo -e "${BY}EJECUTANDO: ./Ejercicio1.sh -s ~/../../tmp/pruebasEjercicio1/resultado.json -d /tmp/pruebasEjercicio1/csv${W}"
./Ejercicio1.sh -s ~/../../tmp/pruebasEjercicio1/resultado.json -d /tmp/pruebasEjercicio1/csv
python3 -mjson.tool ~/../../tmp/pruebasEjercicio1/resultado.json > /dev/null
mostrarResultado $? 0

# echo -e "${Y}Prueba 13: Se le pasa una ruta de salida en la que no tiene permisos para escribir"
# echo -e "Resultado esperado: Error por falta de permisos"
# echo -e "${BY}EJECUTNADO: ./Ejercicio1.sh -s /root -d /tmp/pruebasEjercicio1/resultado.json${W}"
# ./Ejercicio1.sh -s /root -d /tmp/pruebasEjercicio1/resultado.json
# mostrarResultado $? 5
