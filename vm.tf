# Mostly taken from https://search.opentofu.org/provider/bpg/proxmox/latest/docs/guides/clone-vm
# We create a base template which can then be cloned.
# That's the recommended approach for standardized VMs
resource "proxmox_virtual_environment_vm" "debian_template" {
  name      = "debian-template"
  node_name = var.node_name

  bios        = "ovmf" # UEFI, use 'seabios' for BIOS
  description = "Tofu defined Debian VM Template"

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
    file_id      = proxmox_virtual_environment_download_file.debian_13_img.id
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
      keys     = [trimspace(tls_private_key.debian_vm_key.public_key_openssh)]
      password = random_password.debian_vm_password.result
      username = "debian"
    }
    #user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
  }

  network_device {
    // Use the SDN
    bridge = resource.proxmox_virtual_environment_sdn_vnet.vnet1.id
  }
}

// Download a debian 13 image
resource "proxmox_virtual_environment_download_file" "debian_13_img" {
  content_type       = "iso"
  datastore_id       = var.isostore_id
  file_name          = "debian-13-generic-amd64-20251117-2299.img"
  node_name          = "pve"
  url                = "https://cloud.debian.org/images/cloud/trixie/20251117-2299/debian-13-generic-amd64-20251117-2299.qcow2"
  checksum           = "1882f2d0debfb52254db1b0fc850d222fa68470a644a914d181f744ac1511a6caa1835368362db6dee88504a13c726b3ee9de0e43648353f62e90e075f497026"
  checksum_algorithm = "sha512"
}

resource "random_password" "debian_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "debian_vm_key" {
  algorithm = "ED25519"
}

