# Admin UI Setup

## Docker Compose

### 1. Generate Password Hash

```bash
cd stack/admin/app
php -r "echo password_hash('your_password', PASSWORD_BCRYPT, ['cost' => 12]) . PHP_EOL;"
```

### 2. Add to `.env`

```env
WEBADMIN_USERNAME=admin
WEBADMIN_PASSWORD=$2y$12$...hash_from_step_1...
API_SUPER_TOKEN=your_existing_token
```

### 3. Deploy:

```bash
docker-compose --profile admin up -d
```

Access: `http://localhost:8082/login`

## K8s

### 1. Edit `zotprime-k8s/*/helm-chart/values.yaml`:

```yaml
webAdmin:
  enabled: true  # Set to false to disable
  username: ""  # echo -n "admin" | base64
  password: ""  # echo -n "...hash..." | base64   # where hash generated as in step 1 docker: php -r "echo password_hash('your_password', PASSWORD_BCRYPT, ['cost' => 12]) . PHP_EOL;"

```

### 2. Deploy:

```bash
helm upgrade zotprime-k8s helm-chart --namespace zotprime
```

Access: `https://admin.yourdomain.com/login`

## First Login

1. Enter username and password
2. Scan QR code with Google Authenticator
3. Enter 6-digit code