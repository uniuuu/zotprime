# MicroK8s Deployment

## Prerequisites

### 1. Configure TLS (Optional)

For HTTPS:

```bash
cd zotprime-k8s/microk8s
cp clusterissuer-example.yaml clusterissuer.yaml
```

Edit `clusterissuer.yaml` - replace `your-email@example.com`.

Apply:

```bash
kubectl apply -f clusterissuer.yaml
```

## Setup

```bash
cd zotprime-k8s/microk8s/helm-chart
```

### 2. Generate Secrets

**Automated (Recommended):**

Linux/Mac:
```bash
cd ../scripts
./generate-secrets.py
```

Windows (WSL):
```bash
cd ../scripts
wsl ./generate-secrets.py
```

Requires: `python3-yaml` package
```bash
sudo apt install python3-yaml
```

**Manual:**

Copy template and edit all empty `""` fields:
```bash
cp values-example.yaml values.yaml
```

Populate in `values.yaml`:
- `authSecret` (authSalt, apiSuperToken, apiSuperTokenHash, appKey)
- `webAdminConfig` (username)
- `webAdminSecret` (password)
- `minioSecret` (secretTxt)
- `blobSecret` (awsAccessKeyId, awsSecretAccessKey)
- `dbSecret` (mariadbRootPassword, mariadbPassword)
- `zoteroSecret` (adminPassword)
- `webPortalSecret` (sessionSecret)
- `basicAuth` (htpasswd, if enabled)

See `values-example.yaml` comments for generation commands.

### 3. Configure TLS

Edit `values.yaml`:

```yaml
tls:
  enabled: false  # Set true for HTTPS
```

### 4. Configure Domains

Edit `values.yaml` - replace all `yoursub*.yourdomain.tld`:

```yaml
ingressHostnames:
  api: yoursub1.yourdomain.tld
  streamserver: yoursub5.yourdomain.tld
  minios3Data: yoursub2.yourdomain.tld
  phpmyadmin: yoursub3.yourdomain.tld
  minios3Web: yoursub4.yourdomain.tld
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
