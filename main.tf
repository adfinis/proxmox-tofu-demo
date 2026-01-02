// Configure the proxmox provider
provider "proxmox" {
  // endpoint to our proxmox server
  endpoint = "https://10.10.10.2:8006/"

  // see provider docs for authentication setup in prod
  // https://search.opentofu.org/provider/bpg/proxmox/latest#authentication
  username = "root@pam"
  password = "password"

  // self-signed certificate
  insecure = true
}

// Define the Repository. Change if there is a subscription
resource "proxmox_virtual_environment_apt_standard_repository" "no_subscription" {
  // See also https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_apt_standard_repository#required
  // If ceph is used, also add a repo like 'ceph-reef-no-subscription'
  handle = "no-subscription"
  node   = var.node_name
}

// TODO: Should SDN Networks be defined? In the example this could only be used for local-only networking...
// But might still be interesting to readers.
// It's important to note that SDN is currently partially still in tech preview (e.g. automated DHCP/IPAM)
// But since DHCP/IPAM is kinda contradictory to managing state with OpenTofu, it should be OK to not use that.
