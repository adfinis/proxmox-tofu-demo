// Define the required Tofu providers
terraform {
  required_providers {
    // A much simpler alternative only for VM managemnt would be telmate/proxmox:
    // https://search.opentofu.org/provider/telmate/proxmox/latest
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.90.0"
    }
    // To generate a random password using the random_password resource
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    // To generate an SSH key using the tls_private_key resource
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}
