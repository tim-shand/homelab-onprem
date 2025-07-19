# Personal Home Lab

Welcome to my personal home lab! :wave:

This home lab serves to provide an environment for self-hosting and experimenting with different technologies. 
As my knowledge expands, I aim to include new and existing operational, design and security best practices where possible. 
My intention is to utilize automation and DevOps methodologies to ensure a clean and reproducable environment. 

## :classical_building: Physical Hardware

- **Hypervisors**
  - 1x HP EliteDesk G1 (Intel i5-4590T, 16 GB DDR3, 250 GB SSD).
  - Running [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) in single node configuration (for now).
  - In process of obtaining Lenovo Think Center P330 or Lenovo Think Center M720Q for additional **dual-NIC capability**. This will allow me to provide physically separated host & guest networks for better workload isolation (dedicated bandwidth for host-level operations) and improved security (reduced attack surface).
- **Networking**
  - **Switch:** TP-Link TL-SG108PE 8-Port Gigabit Easy Smart PoE Switch.

## :robot: Virtualized Infrastructre

- **Firewall/Router:** Virtualized [pfSense](https://www.pfsense.org/download/) VM (for internal lab use).
- **Virtual Machines:** Management servers, test VMs.

## :cloud: Cloud/SaaS Resources

- **Azure**
  - Platform Landing Zone _(TO BE DEPLOYED)_.
  - Identity platform (Entra ID) for Service Principals used in automation.
- **Cloudflare**
  - Several DNS zones are configured in Cloudflare, and used for various projects.
- **Github**
  - Housing the project and providing code repository.
  - Github Actions for automation pipelines _(considering migration to Azure DevOps)_.

## :dna: Deployment Tool Set

- **Infrastructre-as-Code (IaC)**
  - **[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)** _(DECOM)_
    - Declarative, domain-specific-language (DSL) for the Azure platform.
    - Used to provision initial Azure resources required by Terraform (Storage Account) for utilizing a remote state/backend.
    - **EDIT:** In process of replacing Bicep with bootstrapping scripts.
  - **[Terraform](https://www.terraform.io/)**
    - Provider agnostic IaC tool, free to use, plenty of discussion, guides and support available.
    - Used to provision Proxmox infrastructre using the [BGP](https://registry.terraform.io/providers/bpg/proxmox/latest) provider.
    - Deploy and configure Azure and Cloudflare resources.
    - Other considerations: Pulumi (planning to investigate this further).
  - **Bash/Powershell**
    - Bootstrapping and utility scripts.

## :hammer_and_wrench: To Do

- [-] Migrate 'prep' directory using PS/AzureCLI/Bash for bootstrap and utility scripts. 
- [ ] Review and update Terraform modules, code and structure.
- [ ] Proxmox: Add additional hypervisors for clustering benefits (HA/failover).
- [ ] Configure Azure landing zone.
- [ ] Configure Monitoring and Observability.
- [ ] Investigate implementing a SIEM for logging security events.
