#!/bin/bash


function run(){

    #DECLARACIONES
    #------------------------------------------------
    expreg='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'                                                     #Expresiòn regular para encontrar las ip del output
    dt=$(echo -n ; date | sed 's/ /./g')                                                                                #fecha y hora para la generacion del directorio
    dir="Auditoria/$domain/$dt"                                                                                         #directorio de destino
    #------------------------------------------------

    #EJECUCION
    #------------------------------------------------

    mkdir -p $dir                                                                                                       #Genera el directorio del destino
    echo -e "\n \e[1;35m ejectutando dnsenum para el dominio $domain. El proceso puede llevar unos minutos\e[1;37m \n "
    
    if [ $dnsfile = "none" ] ; then                                                                                     #genera un txt con el resultado 
        dnsenum $domain --noreverse | grep -o $expreg | uniq -u > $dir/ips.txt                                          
    else
        dnsenum -f $dnsfile $domain --noreverse | grep -o $expreg | uniq -u > $dir/ips.txt
    fi
    
    scan
    #------------------------------------------------
}
function scan(){
    shodan init $(cat api.txt)                                                                                          #init de shodan

    i=0
    while read p
    do
    if [ $i == $filter ] ; then
        break
    fi
        echo -e "\n \e[1;32m Buscando informacion para la ip $p \e[1;37m \n "
        sho=$(shodan host $p)
        nm=$(nmap -sV -sC $p)                                               
        echo -e "SHODAN: \n\n $sho \n\n NMAP: \n\n $nm" > $dir/$p.txt                                                   #Genera un txt con el output de shodan y nmap

        i=$((i+1))
    done  < $dir/ips.txt

    echo -e "\n \e[1;32m Scan exitoso, puede visualizar los registros accediendo a esta ruta: \e[1;35m $dir \e[1;37m \n "

}

domain=$1                                                                                                               #dominio
dnsfile=$2                                                                                                              #diccionario dns
filter=$3                                                                                                               #filtro de subdominios
int='^[0-9]+$'

if [ $domain = "-h" ] ; then  
    echo -e "\n arg nº1: Dominio a analizar {Required}  \n"
    echo -e "\n arg nº2: Realizar busqueda con un diccionario customizado {Default: dnsenum} \n"
    echo -e "\n arg nº3: Cantidad de subdominios a analizar {default: max} \n"
    exit 1
fi
if [ $domain = "" ] ; then                                                   #Valida existencia del argumento
    echo -e "\n \e[1;31m Por favor ingresar el destino. \e[1;37m \n"
else
    if [ -z "${dnsfile-unset}" ] ; then
        dnsfile="none"
    fi
    if [ -z "${filter-unset}" ] ; then
        filter=1000
    elif ! [[ $filter =~ $int ]] ; then
        filter=1000
    fi
    run  
fi
exit 1
