# MicroK8s Deployment

## Prerequisites

### 1. Configure cert-manager ClusterIssuer

Edit `zotprime-k8s/microk8s/clusterissuer.yaml`:

```yaml
spec:
  acme:
    email: your-email@example.com  # Replace with your email
```

Apply:

```bash
kubectl apply -f zotprime-k8s/microk8s/clusterissuer.yaml
```

## Setup

```bash
cd zotprime-k8s/microk8s/helm-chart
cp values-example.yaml values.yaml
```

### 2. Configure Credentials

Generate base64-encoded secrets:

**Linux/Mac:**
```bash
echo "MINIO_ROOT_PASSWORD=your_password" | base64
printf "MARIADB_ROOT_PASSWORD=root_pass\nMARIADB_PASSWORD=user_pass" | base64
```

**Windows PowerShell:**
```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("MINIO_ROOT_PASSWORD=your_password"))
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("MARIADB_ROOT_PASSWORD=root_pass`nMARIADB_PASSWORD=user_pass"))
```

Edit `values.yaml`:

```yaml
minioConfig:
  minioUser: your_minio_user

minioSecret:
  secretTxt: "<base64_output_from_minio_command>"

dbConfig:
  mariadbUser: your_db_user
  mariadbDatabasename: your_db_name

dbSecret:
  secretTxt: "<base64_output_from_mariadb_command>"
```

### 2a. Configure Basic Auth

Protect PHPMyAdmin and MinIO web console with HTTP Basic Authentication. This adds a second layer of security at the ingress level before reaching the application's own authentication.

**Install htpasswd:**

Linux:
```bash
sudo apt install apache2-utils
```

Mac:
```bash
brew install httpd
```

Windows (WSL):
```bash
wsl --install
wsl sudo apt install apache2-utils
```

**Generate password hash:**

Linux/Mac:
```bash
htpasswd -nb admin yourpassword | base64
```

Windows (WSL):
```bash
wsl htpasswd -nb admin yourpassword | base64
```

**Edit `values.yaml`:**

```yaml
basicAuth:
  enabled: true
  htpasswd: "<base64_output>"
```

Users will authenticate twice: first at ingress (basic auth), then at application login (PHPMyAdmin/MinIO credentials).

### 3. Configure Domains

Edit `values.yaml`:

```yaml
ingressHostnames:
  api: yoursub1.yourdomain.tld
  streamserver: yoursub5.yourdomain.tld
  minios3Data: yoursub2.yourdomain.tld
  phpmyadmin: yoursub3.yourdomain.tld
  minios3Web: yoursub4.yourdomain.tld

zotprimeDataserver:
  hostAliases:
    hostname: yoursub2.yourdomain.tld  # Match minios3Data
    ip: 10.152.183.11                   # Choose available cluster IP
  zotprimeDataserver:
    env:
      serverIp: http://yoursub1.yourdomain.tld/
      s3Endpoint: yoursub2.yourdomain.tld

minio:
  clusterIP: 10.152.183.11  # Same IP as hostAliases
```

## DNS

Point all 5 subdomains to ingress IP:

```bash
kubectl get ingress -n zotprime  # Get IP after deployment
```

## Deploy

```bash
kubectl create namespace zotprime
helm install zotprime-k8s helm-chart --namespace zotprime
```

## Verify

```bash
kubectl get certificate -n zotprime  # Wait for READY: True
kubectl get pods -n zotprime         # All should be Running
```

## Update

```bash
helm upgrade zotprime-k8s helm-chart --namespace zotprime
```

## Multiple Environments

```bash
cp values-example.yaml values-prod.yaml
helm install zotprime-prod helm-chart -f values-prod.yaml --namespace prod
```
