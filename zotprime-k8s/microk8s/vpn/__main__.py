"""WireGuard VPN deployment for ZotPrime admin access"""
import pulumi
import pulumi_command as command
import os

# Get configuration - fail hard if not set
config = pulumi.Config()
server_url = config.require("serverUrl")
server_port = config.require("serverPort")
peers = config.require("peers")
internal_subnet = config.require("internalSubnet")
peer_dns = config.require("peerDns")

# Paths
config_dir = "./config"
docker_compose_path = f"{config_dir}/docker-compose.yml"
wireguard_data_dir = f"{config_dir}/wireguard-config"

# Create config directory
create_dirs = command.local.Command(
    "create-config-dirs",
    create=f"mkdir -p {config_dir} {wireguard_data_dir}",
)

# Read template and substitute values
with open("docker-compose.template.yml", "r") as f:
    template = f.read()

docker_compose_content = template.format(
    SERVER_URL=server_url,
    SERVER_PORT=server_port,
    PEERS=peers,
    PEER_DNS=peer_dns,
    INTERNAL_SUBNET=internal_subnet,
    WIREGUARD_DATA_DIR=os.path.abspath(wireguard_data_dir)
)

# Write docker-compose.yml
with open(docker_compose_path, "w") as f:
    f.write(docker_compose_content)

# Deploy WireGuard
deploy_wireguard = command.local.Command(
    "deploy-wireguard",
    create=f"docker compose -f {docker_compose_path} up -d",
    delete=f"docker compose -f {docker_compose_path} down",
    update=f"docker compose -f {docker_compose_path} up -d --force-recreate",
    opts=pulumi.ResourceOptions(depends_on=[create_dirs])
)

# Wait for config generation
wait_for_configs = command.local.Command(
    "wait-for-configs",
    create="sleep 10 && echo 'WireGuard configs generated'",
    opts=pulumi.ResourceOptions(depends_on=[deploy_wireguard])
)

# Export outputs
pulumi.export("wireguard_status", deploy_wireguard.stdout)
pulumi.export("config_directory", os.path.abspath(wireguard_data_dir))
pulumi.export("docker_compose_path", os.path.abspath(docker_compose_path))
pulumi.export("peers", peers)
pulumi.export("server_port", server_port)
pulumi.export("instructions", f"""
WireGuard VPN deployed successfully!

Client configs location: {os.path.abspath(wireguard_data_dir)}/peer_<name>/

To get a client config:
  docker exec wireguard-admin cat /config/peer_admin1/peer_admin1.conf

To check status:
  docker logs wireguard-admin

To restart:
  pulumi up --refresh
""")
