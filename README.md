# Personal Home Lab

Welcome to my personal home lab! :wave:
This project provides an environment for self-hosting and experimenting with different technologies. 
A base for hands-on learning, developing knowledge and improving skills in DevOps and Cloud platforms.

## :office: Physical Hardware

### Hypervisors
- 2x Lenovo Think Station P330 (Intel i5 9600T, 16GB DDR4, 250GB OS, 1TB ZFS pool).
  - Running clustered [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) for VMs.
  - Raspberry Pi for maintaining Quorum [details on setup found here](https://www.tshand.com/p/home-lab-part-6-setup-qdevice-for-proxmox-quorum/).
  
### Networking
- **Switch:** TP-Link TL-SG108PE 8-Port Gigabit Easy Smart PoE Switch.
  - Connecting nodes physically, providing outbound access to Internet via firewall connected to home WiFi network.
- **Firewall:** HP EliteDesk G1 (Intel i5-4590T, 16 GB DDR3, 250 GB SSD).
  - Running OPNsense, providing firewall, VLAN and routing functionality.

## :computer: Virtualized Infrastructure

- **Firewall/Router:** Virtualized [pfSense](https://www.pfsense.org/download/) VM (for internal lab use).
- **Virtual Machines:** Management servers, test and misc VMs.

## :cloud: Cloud Services

- **Azure**
  - Platform Landing Zone and web app services.
  - Repo: [Homelab-Azure](https://github.com/tim-shand/homelab-azure)
- **Cloudflare**
  - Several DNS zones are configured in Cloudflare, and used for various personal projects.
- **Github**
  - Housing the project and providing code repository.
  - Github Actions for automation pipelines.

## :hammer_and_wrench: Deployment Tool Set

- **Infrastructre-as-Code (IaC)**
  - **[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)** _(DECOM)_
    - Declarative, domain-specific-language (DSL) for the Azure platform.
    - Used to provision initial Azure resources required by Terraform (Storage Account) for utilizing a remote state/backend.
    - **EDIT:** In process of replacing Bicep with powershell bootstrap scripts.
  - **[Terraform](https://www.terraform.io/)**
    - Provider agnostic IaC tool, free to use, plenty of discussion, guides and support available.
    - Used to provision Proxmox infrastructre using the [BGP](https://registry.terraform.io/providers/bpg/proxmox/latest) provider.
    - Deploy and configure Azure and Cloudflare resources.
    - Other considerations: Pulumi, OpenTofu (planning to investigate these options further).
  - **Bash/Powershell**
    - Bootstrapping and utility scripts.

## :memo: To Do

- [x] Migrate 'prep' directory using PS/AzureCLI/Bash for bootstrap and utility scripts. 
- [x] Configure Azure landing zone.
- [ ] Redeploy on-prem infra using Terraform and CI/CD.
- [ ] Configure Monitoring and Observability (RMM as well).
- [ ] Implement a ticketing system (auto-logging alerts from monitoring platform).
- [ ] Investigate a SIEM for logging security events.
- [ ] Investigate Kubernetes for advanced container orchestration.
