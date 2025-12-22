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
  # use PROXMOX_VE_PASSWORD env var in production
  password = "password"
  # self-signed certificate
  insecure = true
}
