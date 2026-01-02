// Create the SDN zone
resource "proxmox_virtual_environment_sdn_zone_simple" "sdn1" {
  id    = "sdn1"
  nodes = [var.node_name]
  mtu   = 1500

  // could also be netbox
  ipam = "pve"

  dhcp = "dnsmasq"
}

// Create the VNet
resource "proxmox_virtual_environment_sdn_vnet" "vnet1" {
  id   = "vnet1"
  zone = proxmox_virtual_environment_sdn_zone_simple.sdn1.id
}

// Create a subnet with DHCP enabled
resource "proxmox_virtual_environment_sdn_subnet" "dhcp1" {
  cidr            = "10.10.20.0/24"
  vnet            = proxmox_virtual_environment_sdn_vnet.vnet1.id
  gateway         = "10.10.20.1"
  dhcp_dns_server = "10.10.20.1"
  dns_zone_prefix = "proxmox-tofu.demo"
  snat            = true

  dhcp_range = {
    start_address = "10.10.20.10"
    end_address   = "10.10.20.100"
  }
}

// Apply the SDN configuration
resource "proxmox_virtual_environment_sdn_applier" "sdn1" {
  depends_on = [
    proxmox_virtual_environment_sdn_zone_simple.sdn1,
    proxmox_virtual_environment_sdn_vnet.vnet1,
    proxmox_virtual_environment_sdn_subnet.dhcp1
  ]
}
