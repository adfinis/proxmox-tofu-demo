// Mostly taken from https://search.opentofu.org/provider/bpg/proxmox/latest/docs/guides/clone-vm
// We create a base template which can then be cloned.
// That's the recommended approach for standardized VMs
resource "proxmox_virtual_environment_vm" "debian_template" {
  name      = "debian-template"
  node_name = var.node_name

  bios        = "ovmf" // UEFI, use 'seabios' for BIOS
  description = "Tofu defined Debian VM Template"

  template = true
  started  = false

  cpu {
    cores = 1
    // It's possible to use 'host' if the cluster only has one CPU type
    // Though upgrading the Cluster to new CPUs can be tricky/require VM restarts
    // The following is recommended for modern CPUs
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 1024
    floating  = 1024 // set equal to dedicated to enable ballooning
  }

  // Only required for UEFI
  // https://pve.proxmox.com/wiki/Secure_Boot_Setup#Introduction
  efi_disk {
    datastore_id = var.datastore_id
    type         = "4m"
  }

  disk {
    // Gonna be the default "local-lvm"
    datastore_id = var.datastore_id
    file_id      = proxmox_virtual_environment_download_file.debian_13_img.id
    interface    = "virtio0"
    iothread     = true
    // Useful on all filesystems that allow thin-provisioning, as space can be reclaimed
    // E.g. lvm-thin, zfs, ceph, and usually also qcow2
    // For qcow2 on NFS, apparently it requires NFS v4.2;
    // https://pve.proxmox.com/wiki/Shrink_Qcow2_Disk_Files (the note after the first screenshot)
    discard      = "on"
    size         = 20
  }

  // When enabling the guest agent, make sure it's either installed already in the VM image,
  // or that it's installed via cloud-init (see below).
  // Otherwise the provider will hang indefinitely while trying to read the IP from the VM.
  agent {
    enabled = true
  }

  // Defines cloud-init configurations
  initialization {
    // Due to a bug, we must set this to scsiX if we use UEFI.
    // https://forum.proxmox.com/threads/solved-cloud-init-ubuntu-template-vm-uefi-customization.151811/
    interface    = "scsi30"
    datastore_id = var.datastore_id // where the cloud-init disk will be placed
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  operating_system {
    type = "l26" // Linux Kernel 2.6 - 6.X.
  }

  network_device {
    // Use the SDN we created previously
    bridge = resource.proxmox_virtual_environment_sdn_vnet.vnet1.id
  }

  depends_on = [proxmox_virtual_environment_sdn_subnet.dhcp1]
}

// Download a debian 13 image
resource "proxmox_virtual_environment_download_file" "debian_13_img" {
  content_type       = "import"
  datastore_id       = var.isostore_id // "local" storage
  file_name          = "debian-13-generic-amd64-20251117-2299.qcow2"
  node_name          = var.node_name
  url                = "https://cloud.debian.org/images/cloud/trixie/20251117-2299/debian-13-generic-amd64-20251117-2299.qcow2"
  checksum           = "1882f2d0debfb52254db1b0fc850d222fa68470a644a914d181f744ac1511a6caa1835368362db6dee88504a13c726b3ee9de0e43648353f62e90e075f497026"
  checksum_algorithm = "sha512"
}

// This generates a random password.
// It will store the password in clear text in the tofu state file. Make sure to encrypt the state file if you use this method;
// https://opentofu.org/docs/language/state/encryption/
// Best practice would be to use an ephemeral resource for this. But the provider doesn't support that yet.
// See: https://github.com/bpg/terraform-provider-proxmox/issues/2432
resource "random_password" "debian_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "debian_vm_key" {
  algorithm = "ED25519"
}

resource "proxmox_virtual_environment_file" "cloud_config_01" {
  content_type = "snippets"
  datastore_id = var.isostore_id
  node_name    = var.node_name

  // This is just plain cloud-init; https://cloudinit.readthedocs.io/en/latest/index.html
  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: debian-vm-01
    timezone: Europe/Zurich
    users:
      - default
      - name: debian
        password: ${random_password.debian_vm_password.result}
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(resource.tls_private_key.debian_vm_key.public_key_openssh)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "cloud-config-01.yaml"
  }
}

// Clone the previously created template
resource "proxmox_virtual_environment_vm" "debian_vm" {
  name      = "debian-vm-01"
  node_name = var.node_name

  clone {
    vm_id = proxmox_virtual_environment_vm.debian_template.vm_id
    full  = false // Full clone vs linked clone
  }

  memory {
    dedicated = 768
  }

  # TODO: Create a ticket upstream
  # There is a bug that wants to update the IP addresses and interface name every time
  lifecycle {
    ignore_changes = [ipv4_addresses, ipv6_addresses, network_interface_names]
  }
  initialization {
    # Use the previously created cloud-init
    user_data_file_id = proxmox_virtual_environment_file.cloud_config_01.id
  }

  depends_on = [proxmox_virtual_environment_sdn_subnet.dhcp1, proxmox_virtual_environment_file.cloud_config_01]
}

