// The node itself is called "pve", which might be a bit confusing.
// Use a hostname in case of a cluster
variable "node_name" {
  type    = string
  default = "pve"
}

// This is a local lvm-thin volume which comes with the installation
// It's used for VM and Container Disks
// It's possible to create additional lvm-thin pools with Tofu: https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_storage_lvmthin
// For High-Availability, Ceph is recommended (which can't be done with Tofu and should be part of the initial setup docs).
variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

// This is a local directory which comes with the installation
// It's used for Base Images, ISOs and Backups
// It's possible to create additional directory configurations with Tofu: https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_storage_directory
variable "isostore_id" {
  type    = string
  default = "local"
}
