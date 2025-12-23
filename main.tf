// Define the required Tofu providers
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89.1"
    }
  }
}

// Configure the proxmox provider
provider "proxmox" {
  // endpoint to our proxmox server
  endpoint = "https://10.10.10.2:8006/"

  # see provider docs for authentication setup in prod
  # https://search.opentofu.org/provider/bpg/proxmox/latest#authentication
  username = "root@pam"
  password = "password"

  # self-signed certificate
  insecure = true
}
