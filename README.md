# ZotPrime V2 - On-premise Zotero platform

ZotPrime is a fully packaged repository aimed to make on-premise [Zotero](https://www.zotero.org) deployment easier with the last versions of both Zotero client and server. This is the result of sleepness nights spent to deploy Zotero within my organization on a disconnected network. Feel free to open issues or pull requests if you did not manage to use it.

Table of contents
=================

  * [Docker Installation](#docker-installation)
  * [GKE Installation](#gke-installation)
  * [MicroK8s Installation](#microk8s-installation)
  * [Client Build](#client-build)

## Docker Installation
*Identify your Server IP Address*:

You may install ZotPrime server in baremetal, or in virtual machine, or in your PC host - where you would run client too. For any of these installations you will have to identify your Server IP Address. In baremetal it would be IP address of your network interface connected to LAN. In virtual machine it would be either IP address of your hypervisor's or VMM's virtual network interface that is connected to host computer, or it would be IP address of your host's network interface connected to LAN if you want to expose it to LAN for connecting from other computers to this virtual machine, and you will need to do port forwarding from the host's network interface IP address to virtual network interface IP address for all ports listed below under [Available endpoints](#available-endpoints). If you install both server and client in same PC host then you can use 127.0.0.1 (localhost) as Server IP Address.


### Dependencies and source code
*Install latest docker compose plugin*:
```bash
$ sudo apt update
$ sudo apt install docker-compose-plugin
```
*Clone production branch of the repository*:
```bash
$ mkdir /path/to/your/app && cd /path/to/your/app
$ git clone -b production --recursive --single-branch https://github.com/uniuuu/zotprime.git
$ cd zotprime
```
*Configure*:
```bash
$ cp .env_example .env
```
**Edit .env and change DSHOST.**  
```
DSHOST=http://\<Server IP Address\>:8080/

S3HOST=http://\<Server IP Address\>:9000/
```
*Run*:
```bash
$ sudo docker compose up -d
```
### Initialize databases
*Initialize databases*:
```bash
$ ./bin/init.sh
$ cd ..
```
### Available endpoints:

| Name          | URL                                           |
| ------------- | --------------------------------------------- |
| Zotero API    | http://\<Server IP Address\>:8080/                        |
| S3            | http://\<Server IP Address\>:9000/                         |
| PHPMyAdmin    | http://\<Server IP Address\>:8083/                         |
| S3 Web UI     | http://\<Server IP Address\>:9001/                         |
| Stream Server | ws://\<Server IP Address\>:8081/                         |

### Default login/password:

| Name          | Login                    | Password           |
| ------------- | ------------------------ | ------------------ |
| Zotero API    | admin                    | admin              |
| S3 Web UI     | zotero                   | zoterodocker       |
| PHPMyAdmin    | root                     | zotero             |

## GKE Installation
*Clone the repository:*
```bash
$ mkdir /path/to/your/app && cd /path/to/your/app
$ git clone https://github.com/uniuuu/zotprime.git
$ git checkout production  
$ cd zotprime
```
**Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install**  
**Install Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli**  
**Install Kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/**  
**Install Helm: https://helm.sh/docs/intro/install/**  
*Run*:
```bash
$ gcloud init
$ gcloud iam service-accounts create zotprimeprod
$ gcloud projects list
$ gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:NAME@PROJECT_ID.iam.gserviceaccount.com" --role="roles/owner"
```
- <PROJECT_ID> is name of your project ID  
- NAME@PROJECT_ID.iam.gserviceaccount.com is email ID of service account  
*Run*:
```bash
$ cd ./zotprime-k8s/GKE/terraform
$ gcloud iam service-accounts keys create cred.json --iam-account=NAME@PROJECT_ID.iam.gserviceaccount.com
$ mv cred.json ./auth/
$ gcloud services enable container.googleapis.com
$ gcloud services enable cloudresourcemanager.googleapis.com
$ cp terraform.tfvars_example terraform.tfvars
```
**Edit terraform.tfvars and change project_id, region, zones, node-locations, minnode, maxnode, disksize, machine**  
*Run*:
```bash
$ terraform init
$ terraform fmt && terraform validate && terraform plan
$ terraform apply
$ gcloud container clusters get-credentials zotprime-k8s-prod
$ cd ..
```
**Check cluster and install Zotprime Helm Chart**  
*Run*:
```bash
$ kubectl config get-contexts
$ kubectl get all --all-namespaces
```
**Edit ./helm-chart/values.yaml and change dsuri:, s3Pointuri:, api:, streamserver:, minios3Data:, phpmyadmin:, minios3Web: .**  
Replace to your hostnames api (**dsuri:**, **api:**), S3 Minio Data (**s3Pointuri:**, **minios3Data:**), Stream Server (**streamserver:**), Phpmyadmin (**phpmyadmin:**) and S3 Minio Web (**minios3Web:**):  
- dsuri: http://api-any.yourhostname.io/  
- s3Pointuri: s3-any.yourhostname.io  
- api: api-any.yourhostname.io  
- streamserver: stream-any.yourhostname.io  
- minios3Data: s3-any.yourhostname.io  
- phpmyadmin: phpmyadmin-any.yourhostname.io  
- minios3Web: minioweb-any.yourhostname.io  
*Run*:
```bash
$ kubectl create namespace zotprime
$ helm install zotprime-k8s helm-chart --namespace zotprime
$ kubectl get -A cm,secrets,deploy,rs,sts,pod,pvc,svc,ing
```
*Obtain Ingress IP's and setup A records in DNS hosting*:  
Wait while GCP will provision IP's verify with below command output in ADDRESS column  
*Run*:
```bash
$ kubectl get -A ing
```
*Available endpoints*:

| Name          | URL                                           |
| ------------- | --------------------------------------------- |
| Zotero API    | http://api-any.yourhostname.io                |
| S3            | http://s3-any.yourhostname.io                 |
| PHPMyAdmin    | http://phpmyadmin-any.yourhostname.io         |
| S3 Web UI     | http://minioweb-any.yourhostname.io           |
| Stream Server | ws://stream-any.yourhostname.io             |

*Default login/password*:

| Name          | Login                    | Password           |
| ------------- | ------------------------ | ------------------ |
| Zotero API    | admin                    | admin              |
| S3 Web UI     | zotero                   | zoterodocker       |
| PHPMyAdmin    | root                     | zotero             |

## MicroK8s Installation
*Clone the repository:*
```bash
$ mkdir /path/to/your/app && cd /path/to/your/app
$ git clone https://github.com/uniuuu/zotprime.git 
$ git checkout production  
```
**Install Microk8s: https://microk8s.io/docs/getting-started**  
**Install Kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/**  
**Install Helm: https://helm.sh/docs/intro/install/**  
*Install microk8s modules:*
```bash
microk8s enable hostpath-storage
microk8s enable helm
microk8s enable registry
microk8s enable dns
microk8s enable ingress
```
**Enable metallb based on guide https://microk8s.io/docs/addon-metallb. Use available IP range from your LAN.**  
*Run*:
```bash
microk8s enable metallb:<IP-range>
```
**Check cluster**    
*Run*:
```bash
$ kubectl config get-contexts
$ kubectl get all --all-namespaces
```
**Build and push images to Microk8s registry**  
*Run*:
```bash
$ cd zotprime/microk8s/scripts
$ ./buildimages.sh
$ ./pushimages.sh
```
**Install Zotprime Helm Chart**  
*Run*:
```bash
$ cd ../
$ kubectl create namespace zotprime
$ helm install zotprime-k8s helm-chart --namespace zotprime
$ kubectl get -A cm,secrets,deploy,rs,sts,pod,pvc,svc,ing
```
**Obtain Ingress IP's and setup A records in all DNS servers (or add in /etc/hosts) in client and server LAN** 
*Run*:
```bash
$ kubectl get -A ing
```
*Available endpoints*:

| Name          | URL                                           |
| ------------- | --------------------------------------------- |
| Zotero API    | http://api.zotprime               |
| S3            | http://s3min.zotprime              |
| PHPMyAdmin    | http://pm.zotprime         |
| S3 Web UI     | http://min.zotprime           |
| Stream Server | ws://stream.zotprime             |

*Default login/password*:

| Name          | Login                    | Password           |
| ------------- | ------------------------ | ------------------ |
| Zotero API    | admin                    | admin              |
| S3 Web UI     | zotero                   | zoterodocker       |
| PHPMyAdmin    | root                     | zotero             |

## Manage Users and Groups

*Create new users*:
```bash
$ sudo ./bin/create-user.sh {UID} {USERNAME} {PASSWORD} {EMAIL} {LIBRARY ID}
```

*List users*:
```bash
$ sudo docker compose exec zotprime-dataserver /var/www/zotero/admin/list-users.sh
```

*Create shared group libraries*:
```bash
$ sudo docker compose exec zotprime-dataserver /var/www/zotero/admin/create-group.sh {OWNER_USER_NAME} {GROUP_NAME} {GROUP_FULLNAME} 
```

*List groups*:
```bash
$ sudo docker compose exec zotprime-dataserver /var/www/zotero/admin/list-groups.sh
```

*Add users to a group*:
```bash
$ sudo docker compose exec zotprime-dataserver /var/www/zotero/admin/add-user-group.sh {USER_NAME} {GROUP_NAME}
```

*Remove users from a group*:
```bash
$ sudo docker compose exec zotprime-dataserver /var/www/zotero/admin/remove-user-group.sh {USER_NAME} {GROUP_NAME}
```

## Client Build
### Client build from Linux
*Edit and run*:
- For Docker Installation argument's are: 
```
  HOST_DS=http://\<Server IP Address\>:8080/
  HOST_ST=ws://\<Server IP Address\>:8081/
```
- For GKE Installation arguments are:
```
  HOST_DS=http://api-any.yourhostname.io/
  HOST_ST=ws://stream-any.yourhostname.io/
```
- For Microk8s Installation arguments are:
```
  HOST_DS=http://api.zotprime/
  HOST_ST=ws://stream.zotprime/
```
- Edit argument MLW=[w|l]: w=Windows, l=Linux  

*Replace respective arguments in the command below and run it*:  
```bash
$ DOCKER_BUILDKIT=1 docker build --progress=plain --file client.Dockerfile \
      --build-arg HOST_DS=http://<input argument>:8080/ \
      --build-arg HOST_ST=ws://<input argument>:8081/ \
      --build-arg MLW=l --output build .
```
*Run client*:
```bash
$ ./build/staging/Zotero_VERSION/zotero(.exe))
```
### Client build from Mac
For [m]: m=Mac  
*Install Git LFS.*
```bash
sudo port install git-lfs
```
*Run*:
```bash
$ git submodule update --init --recursive
$ cd client
$ ./config.sh
$ cd zotero-client
$ npm install
$ npm run build
$ app/scripts/dir_build -p m
```
*Run client*:
```bash
$ ./staging/Zotero_VERSION/zotero
```
*Connect with the default user and password*:

| Name          | Login                    | Password           |
| ------------- | ------------------------ | ------------------ |
| Zotero        | admin                    | admin              |

![Sync](doc/sync.png)

Credits
1. https://github.com/FiligranHQ/zotprime
2. https://github.com/gfacciol/zotero_dataserver-docker
3. https://github.com/isabekov/dataserver
4. https://github.com/piernov/zotprime
5. https://github.com/Dwarf-Planet-Project/zotero_installation
6. https://github.com/foxsen/zotero-selfhost
7. https://github.com/zehuanli/zotero-selfhost
8. https://github.com/fversaci/zotero-prime
9. https://github.com/victoradrianjimenez/dockerized-zotero
