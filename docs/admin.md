# Admin UI Setup

## 1. Generate Password Hash

```bash
cd stack/admin/app
php -r "echo password_hash('your_password', PASSWORD_BCRYPT, ['cost' => 12]) . PHP_EOL;"
```

## 2. Build Tailwind CSS

```bash
cd stack/admin/app
curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64
chmod +x tailwindcss-linux-x64
./tailwindcss-linux-x64 -i ./resources/css/app.css -o ./public/css/app.css --minify
rm tailwindcss-linux-x64
```

## 3. Add to `.env`

```env
WEBADMIN_USERNAME=admin
WEBADMIN_PASSWORD=$2y$12$...hash_from_step_1...
API_SUPER_TOKEN=your_existing_token
```

## 4. Deploy

### Docker Compose

```bash
docker-compose --profile admin up -d
```

Access: `http://localhost:8082/login`

### Kubernetes

Edit `zotprime-k8s/*/helm-chart/values.yaml`:

```yaml
webAdmin:
  enabled: true  # Set to false to disable
  username: ""  # echo -n "admin" | base64
  password: ""  # echo -n "$2y$12$...hash..." | base64
```

Deploy:

```bash
helm upgrade zotprime-k8s helm-chart --namespace zotprime
```

Access: `https://admin.yourdomain.com/login`

## 5. First Login

1. Enter username and password
2. Scan QR code with Google Authenticator
3. Enter 6-digit code

## Troubleshooting

```bash
# Check logs
docker logs zotprime-admin

# Verify Redis
docker exec zotprime-admin redis-cli ping

# Check environment
docker exec zotprime-admin env | grep WEBADMIN
```
