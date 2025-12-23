# Proxmox Tofu Demo

This repo consists of 3 parts:
- `/proxmox-vagrant-box` is a submodule of https://github.com/adfinis-forks/proxmox-ve to build a new Proxmox Base Box
- `provision/` contains an example configuration to bring up a simple Proxmox in a VM for testing
- `main.tf` is a terraform file that can be used to configure the Proxmox 

## Getting ready

The base box needs to be built using [packer](https://developer.hashicorp.com/packer) and added to vagrant;
```
cd proxmox-vagrant-box/
packer init ./proxmox-ve.pkr.hcl
# TODO: currently only works with libvirt
make build-libvirt
vagrant box add -f proxmox-ve-amd64 metadata.json
```

Now we can start the Proxmox VM:
```
cd provision/
vagrant up
```

## Applying the Tofu

```
tofu init
tofu plan -vars-file=vagrant.tfvars
tofu apply -vars-file=vagrant.tfvars
```
