# Proxmox Tofu Demo

- [Proxmox Tofu Demo](#proxmox-tofu-demo)
  - [Getting ready](#getting-ready)
  - [Applying the Tofu](#applying-the-tofu)
  - [Tofu Configuration Files](#tofu-configuration-files)

This repo consists of 3 parts:
- `/proxmox-vagrant-box` is a submodule of https://github.com/adfinis-forks/proxmox-ve to build a new Proxmox Base Box
- `provision/` contains an example configuration to bring up a simple Proxmox in a VM for testing
- Lots of tofu code that is explained [here](#tofu-configuration-files)

## Getting ready

The base box needs to be built using [packer](https://developer.hashicorp.com/packer) and added to vagrant;
```
cd proxmox-vagrant-box/
packer init ./proxmox-ve.pkr.hcl
# TODO: currently only works with libvirt
make build-libvirt
vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box.json
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

## Tofu Configuration Files

To keep the code clear and structured, the tofu configuration is split into multiple files.


| File | Description|
|--------------|-----------------------------------------------------|
|`versions.tf` | Contains all required providers and their versions. |
| `variables.tf` | Contains all input variables. |
| `outputs.tf` | All the outputs are defined here. |
| `main.tf` | Provider configuration and general stuff that didn't fit anywhere else. |
| `network.tf` | Proxmox network & SDN definitions. |
| `vm.tf` | VM related configurations. |
