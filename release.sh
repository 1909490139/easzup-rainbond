#!/bin/bash
IMAGE_BASE_NAME=goodrain.me

version=5.2-boe-enterprise
pluginsversion=5.1.7

getDate() {
 date '+%Y-%m-%d'
}

buildtime=$(getDate)-${version}

os=$(uname -s)
uid=$(id -u)
if [ "$os" == "Darwin" -a "$uid" != 0 ]; then
    offline_image_path="$PWD/opt/rainbond/offline/images"
    osstool=ossutilmac64
    shatool='shasum -a 256'
else
    offline_image_path="/opt/rainbond/offline/images"
    osstool=ossutil64
    shatool=sha256sum
fi

path=${offline_image_path}/rainbond
mkdir -pv $path

rainbond=(api chaos gateway monitor mq webcli worker eventlog grctl node app-ui)

r6d:component(){
    local plugins=(plugins-tcm)
    for pimg in "${plugins[@]}"
    do
        docker pull rainbond/${pimg}:${pluginsversion}
        docker tag rainbond/${pimg}:${pluginsversion} goodrain.me/tcm
        [ -f "${path}/${pimg}.tgz" ] && rm -rf ${path}/${pimg}.tgz
        docker save goodrain.me/tcm> ${path}/${pimg}.tgz
    done
    local plugins=(rbd-init-probe rbd-mesh-data-panel)

    for pimg in "${plugins[@]}"
    do
        docker tag ${IMAGE_BASE_NAME}/${pimg}:${version} goodrain.me/${pimg}
        [ -f "${path}/${pimg}.tgz" ] && rm -rf ${path}/${pimg}.tgz
        docker save goodrain.me/${pimg}> ${path}/${pimg}.tgz
    done

    for img in "${rainbond[@]}"
    do
        [ -f "${path}/${img}.tgz" ] && rm -rf ${path}/${img}.tgz
        docker save ${IMAGE_BASE_NAME}/rbd-${img}:${version} > ${path}/${img}.tgz
    done
    docker pull rainbond/builder:5.2.0
    docker tag rainbond/builder:5.2.0 goodrain.me/builder
    docker save goodrain.me/builder > ${offline_image_path}/rainbond/builder.tgz
}

r6d::common(){
    local base=(rbd-dns runner kube-state-metrics mysqld-exporter)
    for img in "${base[@]}"
    do
        [ -f "${path}/${img}.tgz" ] && rm -rf "${path}/${img}.tgz"
        docker pull "rainbond/${img}"
        docker tag "rainbond/${img}" "goodrain.me/${img}"
        docker save "goodrain.me/${img}" > "${path}/${img}.tgz"
    done
    docker pull rainbond/rbd-repo:6.16.0
    docker tag rainbond/rbd-repo:6.16.0 goodrain.me/rbd-repo:6.16.0
    docker save goodrain.me/rbd-repo:6.16.0 > ${path}/repo.tgz
    docker pull rainbond/rbd-registry:2.6.2
    docker tag rainbond/rbd-registry:2.6.2 goodrain.me/rbd-registry:2.6.2
    docker save goodrain.me/rbd-registry:2.6.2 > ${path}/hub.tgz
    docker pull rainbond/rbd-db:8.0.19
    docker tag rainbond/rbd-db:8.0.19 goodrain.me/rbd-db:8.0.19
    docker save goodrain.me/rbd-db:8.0.19 > ${path}/db.tgz
    docker pull rainbond/metrics-server:v0.3.6
    docker tag rainbond/metrics-server:v0.3.6 goodrain.me/metrics-server:v0.3.6
    docker save goodrain.me/metrics-server:v0.3.6 > ${path}/metrics.tgz
}

rainbond_tgz(){
    r6d:component
    r6d::common
    pushd $offline_image_path
        [ -f "$offline_image_path/rainbond.images.${buildtime}.tgz" ] && rm -rf $offline_image_path/rainbond.images.${buildtime}.tgz
        tar zcvf $offline_image_path/rainbond.images.${buildtime}.tgz `find .  | sed 1d`
        ${shatool}  $offline_image_path/rainbond.images.${buildtime}.tgz | awk '{print $1}' > $offline_image_path/rainbond.images.${buildtime}.sha256sum.txt
        mkdir dist
        mv $offline_image_path/rainbond.images.${buildtime}.tgz dist/rainbond.images.${buildtime}.tgz
        mv $offline_image_path/rainbond.images.${buildtime}.sha256sum.txt dist/rainbond.images.${buildtime}.sha256sum.txt
    popd
}

case $1 in
	rainbond)
    if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
		rainbond_tgz push
    else
        rainbond_tgz
    fi    
	;;
	*)
		rainbond_tgz
	;;
esac
