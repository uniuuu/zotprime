provider "google" {
  credentials = file("auth/cred.json")
}

module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  project_id   = var.project_id
  network_name = "${var.network}-${var.env_name}"
  subnets = [
    {
      subnet_name   = "${var.subnetwork}-${var.env_name}"
      subnet_ip     = "10.10.0.0/16"
      subnet_region = var.region
    },
  ]
  secondary_ranges = {
    "${var.subnetwork}-${var.env_name}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "10.30.0.0/16"
      },
    ]
  }
}

module "gke" {
  source            = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id        = var.project_id
  name              = "${var.cluster_name}-${var.env_name}"
  regional          = false
  region            = var.region
  zones             = ["asia-southeast2-c"]
  network           = module.gcp-network.network_name
  subnetwork        = module.gcp-network.subnets_names[0]
  ip_range_pods     = var.ip_range_pods_name
  ip_range_services = var.ip_range_services_name
  remove_default_node_pool = true
  node_pools = [
    {
      name           = "node-pool"
      machine_type   = "n2-standard-2"
      node_locations = "asia-southeast2-c"
      min_count      = var.minnode
      max_count      = var.maxnode
      disk_size_gb   = var.disksize
      preemptible    = false
      auto_repair    = false
      auto_upgrade   = true
    },
  ]
}
output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}