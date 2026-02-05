// Configure the proxmox provider
provider "proxmox" {
  // endpoint to our proxmox server
  endpoint = "https://10.10.10.2:8006/"

  // see provider docs for authentication setup in prod
  // https://search.opentofu.org/provider/bpg/proxmox/latest#authentication
  // Typically you'd want to create an API Token and add it as an environment variable in the CI
  username = "root@pam"
  password = "password"

  // self-signed certificate.
  // It's possible to use Tofu to manage the certificate (https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_certificate)
  // But this is a bit of a chicken-egg-problem. On first execution the certificate is not available (as tofu will deploy it), requiring `insecure`
  // The recommendation is to keep the certificate setup a part of the initial (usually manual) setup of the Proxmox Nodes, or manage it in a separate TF module which has `insecure = true`
  insecure = true
}

// Define the Repository. Change if there is a subscription
resource "proxmox_virtual_environment_apt_standard_repository" "no_subscription" {
  // See also https://search.opentofu.org/provider/bpg/proxmox/latest/docs/resources/virtual_environment_apt_standard_repository#required
  // If ceph is used, also add a repo like 'ceph-reef-no-subscription'
  handle = "no-subscription"
  node   = var.node_name
}
