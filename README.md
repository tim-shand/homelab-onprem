# Personal Home Lab

_My personal home lab, running Proxmox and Kubernetes, configured/deployed using GitOps and IaC toolsets._

The purpose of this homelab is provide an environment to self host and learn new technologies.

This homelab runs on Proxmox VE hypervisors, combined with virtualized Kubernetes nodes operating in a cluster.
I also try leverage Azure services (Key Vault, App Registrations, Storage etc) where suitable.
The physical simplicty of the lab reflects my minimalist-style mindset; small foot print and reduced clutter.
I have always had a fondness for the small form factor/mini PCs.
Being reasonably priced and fairly common, they make great additions to the lab as hosts.

Where feasible, I aim to keep in line with best practices.  
As I develop my skills further, changes will likely occur and new additions will be made.  

## Infrastructure

### Hypervisors

- This is where Micro PCs and Small Form Factor shines.
- HP EliteDesk G1 (Intel i5-4590T, 16 GB DDR3, 250 GB SSD).
- Running [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) in single node configuration (for now).

### Networking

- **Switch:** TP-Link TL-SG108PE 8-Port Gigabit Easy Smart PoE Switch
- **Firewall/Router:** Virtualized [pfSense](https://www.pfsense.org/download/) VM (for internal lab use)

### Kubernetes

- Currently under development.
- 1x Master Node (Control Plane)
- 2x Worker Nodes

## Deployment Tool Set

- **Infrastructre-as-Code (IaC)**
  - [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
    - Declarative, domain-specific-language (DSL) for the Azure platform.
    - Used to provision initial Azure resources required by Terraform (Storage Account) for utilizing a remote state/backend.
  - [Terraform](https://www.terraform.io/)
    - Free, easy to learn, agnostic IaC tool.
    - Used to provision Proxmox virtual infrastructre (VMs, vNets) using the [BGP](https://registry.terraform.io/providers/bpg/proxmox/latest) provider.
    - Also used to provision additonal Azure and Cloudflare resources.
    - Chosen as it is provider agnostic, plenty of discussion, guides and support available.
    - Other considerations: Pulumi (planning to investigate this further).

- **Configuration**
  - [Ansible](https://www.redhat.com/en/ansible-collaborative)
    - Free to use configuration management tool.
    - Maintain configuration states (install applications, deploy settings post deployment).
    - Chosen due to the large amount of community discussion and support.

## To Do / Implement

- [ ] Configure Monitoring and Observability.
- [ ] Investigate implementing a SIEM for logging security events.
- [ ] Add additional hypervisors for clustering benefits (HA/failover).
