terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.10.10.2:8006/"

  username = "root@pam"

  # see provider docs for authentication setup in prod
  # https://search.opentofu.org/provider/bpg/proxmox/latest#authentication
  password = "password"

  # self-signed certificate
  insecure = true
}
