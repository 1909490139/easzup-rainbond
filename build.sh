#!/bin/bash

rainbond_source_dir=.build/rainbond
rainbond_ui_source_dir=.build/rainbond-ui
rainbond_console_source_dir=.build/rainbond-console
image_repo="goodrain.me"
VERSION=5.2-boe-enterprise

build::rainbond-region(){
    mkdir $rainbond_source_dir
    tar -zxf rainbond-boe-enterprise.tar.gz -C $rainbond_source_dir
    echo "start extract code file"
    cp rainbond-build.sh $rainbond_source_dir/release.sh
    pushd $rainbond_source_dir || exit
    echo "extract code file success"
    make image
    popd || exit
    rm -rf $rainbond_source_dir
}

build::rainbond-console-ui(){
    mkdir $rainbond_ui_source_dir
    echo "start extract code file"
    tar -zxf rainbond-console-ui-boe-enterprise.tar.gz -C $rainbond_ui_source_dir
    echo "extract code file success"
    pushd $rainbond_ui_source_dir || exit
    docker run -it --rm -v "$(pwd)":/app -w=/app node:12 npm install --registry=https://registry.npm.taobao.org && npm run build
    if [ ! -d "./dist" ];then
        exit 1;
    fi
    docker build -t "$image_repo/rainbond-ui:$VERSION" -f Dockerfile.release .
    popd || exit
    rm -rf $rainbond_ui_source_dir
}

build::rainbond-console(){
    mkdir $rainbond_console_source_dir
    echo "start extract code file"
    tar -zxf rainbond-console-boe-enterprise.tar.gz -C $rainbond_console_source_dir
    echo "extract code file success"
    pushd $rainbond_console_source_dir || exit
    sed -i "s/VERSION/${VERSION}/g" Dockerfile.release
    sed -i "s/IMAGE_DOMAIN/${image_repo}/g" Dockerfile.release
    sed "s/__RELEASE_DESC__/${VERSION}/" Dockerfile.release > Dockerfile.build
    docker build -t "${image_repo}/rbd-app-ui:${VERSION}" -f Dockerfile.build .
    popd || exit
    rm -rf $rainbond_console_source_dir
}


build::rainbond-region
build::rainbond-console-ui
build::rainbond-console