# Proxmox Tofu Demo

- [Proxmox Tofu Demo](#proxmox-tofu-demo)
  - [Getting ready (for the demo)](#getting-ready-for-the-demo)
  - [Applying the Tofu](#applying-the-tofu)
  - [Tofu Configuration Files](#tofu-configuration-files)
  - [Tipps](#tipps)
    - [VM Credentials](#vm-credentials)
    - [Connect to the SDN](#connect-to-the-sdn)

This repo consists of 4 parts:
- `/proxmox-vagrant-box` is a submodule of https://github.com/adfinis-forks/proxmox-ve to build a new Proxmox Base Box
- `provision/` contains an example configuration to bring up a simple Proxmox in a VM for testing
- Lots of tofu code that is explained [here](#tofu-configuration-files)
- A guide about how to deploy proxmox in  [production](./PRODUCTION.md)

> [!NOTE]
> We are using Vagrant to provision a simple proxmox instance inside libvirt. This is just for demo purposes and to test the tofu code inside a GitHub action. If you are just here for the tofu code, please feel free to ignore everything in the `provision` and `proxmox-vagrant-box`.


## Getting ready (for the demo)

The base box needs to be built using [packer](https://developer.hashicorp.com/packer) and added to vagrant;
```
cd proxmox-vagrant-box/
packer init ./proxmox-ve.pkr.hcl
make build-libvirt
vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box.json
```

> [!TIP]
> If you want to test this with a different hypervisor than libvirt, checkout https://github.com/rgl/proxmox-ve

Now we can start the Proxmox VM:
```
cd provision/
vagrant up
```

## Applying the Tofu

```bash
# initialize the tofu state and install the providers
tofu init

# run a plan, to see what resources will be created
tofu plan

# actually create the resources
tofu apply
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

## Tipps

### VM Credentials

The tofu code will create at least one VM, staging it using cloud-init. Read the tofu outputs to get the VM credentials:

```bash
tofu output -show-sensitive
```

### Connect to the SDN

In [`network.tf`](./network.tf) we create a proxmox [SDN](https://pve.proxmox.com/pve-docs/chapter-pvesdn.html) which is used by our demo VM. Your local machine doesn't know about that network yet, so if you try to connect to the IP of the VM, it will most likely not work.

Add a custom route for the SDN network, so your machine can connect to it:

```bash
ip route add 10.10.20.0/24 via 10.10.10.2
```