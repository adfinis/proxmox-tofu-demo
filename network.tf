// We're basically doing the following declaratively (expecting dnsmasq to be set up on the Proxmox):
// https://pve.proxmox.com/wiki/Setup_Simple_Zone_With_SNAT_and_DHCP

// We're using SDN here, which is somewhat new.
// It has the advantage of stretching across the whole cluster, while the network adapters would need to be configured on each node individually
// It also has support for additional features like QinQ, VXlan or EVPN.
// With a manual installation, it requires some extra steps to work:
// See also for an explanation of the abstractions: https://pve.proxmox.com/pve-docs/chapter-pvesdn.html#pvesdn_installation
// Create the SDN zone
resource "proxmox_virtual_environment_sdn_zone_simple" "sdn1" {
  id    = "sdn1"
  nodes = [var.node_name]
  mtu   = 1500

  // could also be netbox/phpipam
  // Proxmox docs: https://pve.proxmox.com/pve-docs/chapter-pvesdn.html#pvesdn_config_ipam
  // Currently the IPAM itself can't be configured via the bpg provider.
  ipam = "pve"

  dhcp = "dnsmasq"
}

// Create the VNet
// This is a simple "local-only" net to attach VMs, meaning that access to and from the vm needs to be routed via the proxmox node IP address
// Using the Proxmox nodes as router in this fashion is discouraged.
// Usually the Proxmox IP Adress is in a completely separate network
resource "proxmox_virtual_environment_sdn_vnet" "vnet1" {
  id   = "vnet1"
  zone = proxmox_virtual_environment_sdn_zone_simple.sdn1.id
}

// Create a subnet with DHCP enabled
// New systems will automatically be populated in the IPAM
resource "proxmox_virtual_environment_sdn_subnet" "dhcp1" {
  cidr            = "10.10.20.0/24"
  vnet            = proxmox_virtual_environment_sdn_vnet.vnet1.id
  gateway         = "10.10.20.1"
  dhcp_dns_server = "10.10.20.1"
  dns_zone_prefix = "proxmox-tofu.demo"
  // The VM will have internet access via the Proxmox
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
