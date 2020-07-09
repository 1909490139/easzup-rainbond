## 单组件编译

> 单组件编译在实际开发过程中非常重要，由于Rainbond系统的体系较为庞大，平时开发过程中通常是修改了某个组件后编译该组件，使用最新的组件镜像在已安装的开发测试环境中直接替换镜像。

单组件编译支持以下组件：
* chaos 
* api 
* gateway 
* monitor 
* mq 
* webcli 
* worker 
* eventlog 
* init-probe 
* mesh-data-panel 
* grctl 
* node

编译方式如下：

以`chaos`组件为例，在rainbond代码主目录下执行 `make image WHAT=chaos`
> 请注意，该编译脚本依赖git，使用交付的代码包编译前，请先执行`git init`，将代码使用`git`管理起来。

## 完整安装包打包编译

> 编译完整安装包适用于改动了较多的源代码之后，重新生成安装包。 

前提要求：

1. 网络环境较好。
2. 已安装Docker环境。

安装包的编译方式如下：

```
./build.sh
./release.sh 
```
执行成功后将在`dist`目录下生成最新的安装包。若失败根据实际失败原因排查，大多数情况下是由于网络故障编译失败。

## 离线安装包制作

前提要求：

1. 网络环境较好。
2. 已安装Docker环境。
3. 镜像编译完成

离线包制作方式

```bash
./offline -D
cd /etc/ansible 
tar zcvf rainbond-boe.tgz ./*
```

执行成功后所有离线资源都已经打包至`/etc/ansible/rainbond-boe.tgz`文件中，将该文件拷贝至需要安装的节点后，根据下文开始安装

## 基于安装包的安装

前提要求：

1. 离线安装包已经拷贝至需安装的节点

安装步骤：

1. 将离线包解压至指定目录

   ```bash
   #解压至需安装节点的/etc/ansible目录中
   mkdir /etc/ansible
   tar xvf rainbond-boe.tgz -C /etc/ansible
   #进入安装程序所在目录
   cd /etc/ansible/tools
   #确认安装包完整性
   ./easzup -D
   ```

2. 最小化安装k8s（安装集群请忽略）

   ```bash
   ./easzup -S && docker exec -it kubeasz easzctl start-aio
   ```

3. 安装k8s集群

   - 依照规划修改配置文件

     ```bash
     #拷贝模版配置文件
     cp /etc/ansible/example/hosts.multi-node /etc/ansible/hosts
     #修改模版配置文件
     vim /etc/ansible/hosts
     ```

   - 配置文件说明

     ```yaml
     # etcd集群节点数应为1、3、5...等奇数个，不可设置为偶数
     # 变量NODE_NAME为etcd节点在etcd集群中的唯一名称，不可相同
     # etcd节点主机列表
     [etcd] 
     192.168.1.1   NODE_NAME=etcd1
     192.168.1.2   NODE_NAME=etcd2
     192.168.1.3   NODE_NAME=etcd3
     
     # kubernetes master节点主机列表
     [kube-master]
     192.168.1.1
     192.168.1.2
     
     # kubernetes node节点主机列表
     [kube-node]
     192.168.1.3
     192.168.1.4
     
     # [可选] harbor服务，docker 镜像仓库
     # 'NEW_INSTALL':设置为 yes 会安装harbor服务；设置为 no 不安装harbor服务
     # 'SELF_SIGNED_CERT':设置为 no 你需要将 harbor.pem 和 harbor-key.pem 文件放在 down 目录下
     [harbor]
     #192.168.1.8 HARBOR_DOMAIN="harbor.yourdomain.com" NEW_INSTALL=no SELF_SIGNED_CERT=yes
     
     # [可选] 外部负载均衡节点主机列表
     [ex-lb]
     #192.168.1.6 LB_ROLE=backup EX_APISERVER_VIP=192.168.1.250 EX_APISERVER_PORT=8443
     #192.168.1.7 LB_ROLE=master EX_APISERVER_VIP=192.168.1.250 EX_APISERVER_PORT=8443
     
     # [可选] 集群ntp服务器列表
     [chrony]
     #192.168.1.1
     
     [all:vars]
     # --------- Main Variables ---------------
     # 可以选择的kubernetes集群运行时: docker, containerd
     CONTAINER_RUNTIME="docker"
     
     # kubernetes网络插件: calico, flannel, kube-router, cilium, kube-ovn
     CLUSTER_NETWORK="flannel"
     
     # kube-proxy服务代理模式: 'iptables' or 'ipvs'
     PROXY_MODE="ipvs"
     
     # K8S Service CIDR, 不可与主机网络重叠
     SERVICE_CIDR="10.68.0.0/16"
     
     # Cluster CIDR (Pod CIDR), 不可与主机网络重叠
     CLUSTER_CIDR="172.20.0.0/16"
     
     # Node端口范围
     NODE_PORT_RANGE="20000-40000"
     
     # 集群DNS域名
     CLUSTER_DNS_DOMAIN="cluster.local."
     
     # -------- Additional Variables (don't change the default value right now) ---
     # 二进制文件目录
     bin_dir="/opt/kube/bin"
     
     # 证书文件目录
     ca_dir="/etc/kubernetes/ssl"
     
     # 部署目录 (kubeasz工作空间)
     base_dir="/etc/ansible"
     ```

   - 执行集群安装操作

     ```bash
     ./easzup -S && docker exec -it kubeasz ansible-playbook /etc/ansible/90.setup.yml
     ```

4. 修改Rainbond配置文件

   ```bash
   vim /opt/kube/rainbond/chart/values.yaml
   #将该字段修改为定制版本的镜像tag，不修改打包脚本的情况下应该为 5.2-boe-enterprise
   rainbondVersion: v5.2.0-release
   #将operator的镜像地址修改为 goodrain.me/rainbond-operator
   rainbondOperator:
     name: rainbond-operator
     image:
       repository: registry.cn-hangzhou.aliyuncs.com/goodrain/rainbond-operator
   #将openapi的镜像地址修改为 goodrain.me/rbd-op-ui
   openapi:
     name: openapi
     image:
       repository: registry.cn-hangzhou.aliyuncs.com/goodrain/rbd-op-ui
   #将该字段修改为定制版本的镜像仓库，不修改打包脚本的情况下应该为 goodrain.me
   rainbond:
     imageRepository: registry.cn-hangzhou.aliyuncs.com/goodrain
   ```

5. 安装rainbond-operator

   ```bash
   kubectl create namespace rbd-system
   helm install rainbond-operator /opt/kube/rainbond/chart -n rbd-system
   ```

6. 进入UI界面进行后续安装操作