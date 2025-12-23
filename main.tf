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

# Define the Repository. Change if there is a subscription
resource "proxmox_virtual_environment_apt_standard_repository" "no_subscription" {
  # See also https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_apt_standard_repository#required
  # If ceph is used, also add a repo like 'ceph-reef-no-subscription'
  handle = "no-subscription"
  node   = var.node_name
}

# TODO: Should SDN Networks be defined? In the example this could only be used for local-only networking...
# But might still be interesting to readers.
# It's important to note that SDN is currently partially still in tech preview (e.g. automated DHCP/IPAM)
# But since DHCP/IPAM is kinda contradictory to managing state with OpenTofu, it should be OK to not use that.

# Mostly taken from https://search.opentofu.org/provider/bpg/proxmox/latest/docs/guides/clone-vm
# We create a base template which can then be cloned.
# That's the recommended approach for standardized VMs
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name      = "ubuntu-template"
  node_name = var.node_name

  bios        = "ovmf" # UEFI, use 'seabios' for BIOS
  description = "Tofu defined Ubuntu VM Template"

  template = true
  started  = false

  cpu {
    cores = 1
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = 1024
    floating  = 1024 # set equal to dedicated to enable ballooning
  }

  # Only required for UEFI
  # https://pve.proxmox.com/wiki/Secure_Boot_Setup#Introduction
  efi_disk {
    datastore_id = var.datastore_id
    type         = "4m"
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  # Defines cloud-init configurations
  initialization {
    #ip_config {
    #  ipv4 {
    #    address = "dhcp"
    #  }
    #}
    datastore_id = var.datastore_id # where the cloud-init disk will be placed

    # This generates a password everytime.
    # Useful for a demo, but a bit cumbersome. Best is to use a keystore integration
    # e.g. https://search.opentofu.org/provider/hashicorp/vault/v4.0.0 -> TODO: Can this provider also be used with https://openbao.org/?
    user_account {
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
      password = random_password.ubuntu_vm_password.result
      username = "ubuntu"
    }
    #user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
  }

  network_device {
    # This is the default vmbridge perfectly fine for a demo
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "import"
  datastore_id = var.isostore_id
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "noble-server-cloudimg-amd64.qcow2"
}

resource "random_password" "ubuntu_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

