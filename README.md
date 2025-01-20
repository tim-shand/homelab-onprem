# Personal Home Lab

_My personal home lab, running Proxmox and Kubernetes, configured/deployed using GitOps and IaC toolsets._

The purpose of this environment is provide myself a place to tinker and learn new technologies.

My homelab runs on Proxmox VE hypervisors, combined with virtualized Kubernetes nodes operating in a cluster.
The simplicty of my homelab reflects my minimalist-style mindset; small foot print and reduced clutter.
I have always had a fondness for the small form factor/mini PCs.
Being reasonably priced and still fairly common, they make such great additions to the lab.

Where feasible, I will aim to keep in line with best practices.  
As I develop my skills further, changes will likely occur and new additions will be made.  

## Infrastructure

### Hypervisors

- Running [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) in single node configuration (for now).
- 1x HP EliteDesk G1
  - CPU: Intel i5-4590T (4 cores, 4 threads).
  - RAM: 12 GB DDR3 (2x SODIMM)
  - Disk: 250 GB SSD

### Networking

- **Switch:** TP-Link TL-SG108PE 8-Port Gigabit Easy Smart PoE Switch
- **Firewall/Router:** Virtualized [pfSense](https://www.pfsense.org/download/) VM (internal lab use only)

### Kubernetes

- 1x Master Node (Control Plane)
- 2x Work Nodes

## Deployment Tool Set

- **Infrastructre-as-Code (IaC)**
  - [Terraform](https://www.terraform.io/)
    - Free, easy to learn, agnostic IaC tool.
    - Used to provision my Proxmox virtual infrastructre (VMs, vNets etc) using the [BGP](https://registry.terraform.io/providers/bpg/proxmox/latest) provider.
- **Configuration**
  - [Ansible](https://www.redhat.com/en/ansible-collaborative)
    - Free configuration management tool.
    - Maintain configuration states (install applications, deploy settings post deployment etc).
- **GitOps**
  - TBC
- **Kubernetes**
  - TBC
