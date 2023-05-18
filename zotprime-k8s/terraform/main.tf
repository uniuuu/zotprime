provider "google" {
  credentials = file("auth/cred.json")
}

module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version      = "26.0.0"
  depends_on   = [module.k8s]
  project_id   = var.project_id
  location     = module.k8s.location
  cluster_name = module.k8s.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}


module "vpc" {
  source       = "terraform-google-modules/network/google"
  project_id   = var.project_id
  network_name = "${var.network}-${var.env_name}"
  version      = "~> 7.0"
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

module "k8s" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                  = "26.0.0"
  project_id               = var.project_id
  name                     = "${var.cluster_name}-${var.env_name}"
  regional                 = false
  region                   = var.region
  zones                    = ["asia-southeast2-c"]
  network                  = module.vpc.network_name
  subnetwork               = module.vpc.subnets_names[0]
  ip_range_pods            = var.ip_range_pods_name
  ip_range_services        = var.ip_range_services_name
  remove_default_node_pool = true
  initial_node_count       = 1
  node_pools = [
    {
      name           = "nodepool"
      machine_type   = "n1-standard-1"
      node_locations = "asia-southeast2-c,asia-southeast2-a"
      min_count      = var.minnode
      max_count      = var.maxnode
      disk_size_gb   = var.disksize
      preemptible    = false
      auto_repair    = false
      auto_upgrade   = true
    },
  ]
  cluster_resource_labels = { "env" : "var.env_name" }
}



