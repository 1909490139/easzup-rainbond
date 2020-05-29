#!/bin/bash

function ansible_image_list(){
    cat images_list | tr "/" ":" | awk -F":" '{print $3".tgz"}' | while read line ;do 
        sed -i "/with_items/a\            \- \"$line\"" ./install-rainbond/tasks/main.yml ;
    done
}

function build_kubeasz_image(){

    ansible_image_list

    docker build -t linux2573/kubeasz:2.1.0 .
    docker login -ulinux2574 -plinux.root
    docker push linux2573/kubeasz:2.1.0
}

function run_easzup(){

    ./easzup -R
    
}
function main() {
    # check if use bash shell
    readlink /proc/$$/exe|grep -q "dash" && { echo "[ERROR] you should use bash shell, not sh"; exit 1; }
    # check if use with root
    [[ "$EUID" -ne 0 ]] && { echo "[ERROR] you should run this script as root"; exit 1; }

    [[ "$#" -eq 0 ]] && { usage >&2; exit 1; }

    export REGISTRY_MIRROR="CN"
    ACTION=""
    while getopts "CDSd:e:k:m:p:z:" OPTION; do
        case "$OPTION" in
            I)
                ACTION="build_kubeasz_image"
                ;;
            D)
                ACTION="run_easzup"
                ;;
        esac
    done

    [[ "$ACTION" == "" ]] && { echo "[ERROR] illegal option"; usage; exit 1; }

    # excute cmd "$ACTION" 
    echo -e "[INFO] \033[33mAction begin\033[0m : $ACTION"
    ${ACTION} || { echo -e "[ERROR] \033[31mAction failed\033[0m : $ACTION"; return 1; }
    echo -e "[INFO] \033[32mAction successed\033[0m : $ACTION"
}

main "$@"

