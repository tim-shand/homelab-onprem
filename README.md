# Personal Home Lab

Welcome to my personal home lab! :wave:  
This project provides an environment for self-hosting and experimenting with different technologies.  
A base for hands-on learning, developing knowledge and improving skills in DevOps and Cloud platforms.  
Bootstrapped, deployed, and managed using Infra-as-Code and CI/CD workflows.  

## :office: Physical Hardware (On-Prem)

### Hypervisors (Proxmox)

- 2x Lenovo Think Station P330 (Intel i5 9600T, 16GB DDR4, 250GB OS, 1TB ZFS pool). 
  - Running clustered [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) for VMs. 
  - Raspberry Pi for QDevice, maintaining Quorum [details on setup found here](https://www.tshand.com/p/home-lab-part-6-setup-qdevice-for-proxmox-quorum/). 
  - Currently investigating NAS options to add improved high availability :eyes:. 
  
### Networking

- **Switch:** TP-Link TL-SG108PE 8-Port Gigabit Easy Smart PoE Switch. 
  - Connecting nodes physically, providing outbound access to Internet via firewall connected to home WiFi network. 
- **Firewall:** HP EliteDesk G1 (Intel i5-4590T, 16 GB DDR3, 250 GB SSD). 
  - Running [OPNsense](https://opnsense.org/) providing firewall, VLAN and routing functionality. 
  - Separate VLANs for infrastructure, management and workloads. 

## :computer: Virtualized Infrastructure

- **Firewall/Router:** Virtualized [pfSense](https://www.pfsense.org/download/) VM (for internal lab use). 
- **Virtual Machines:** Management servers, CI/CD runners, test and misc utility VMs. 

## :cloud: Cloud Services

### Azure

- Automated bootstrapping using Powershell script.
  - Generates required Terraform files, kicks of deployment, triggers post-deployment state migration to Azure. 
  - Creates Entra ID Service Principal, secured with Federated Credentials (OIDC), and added to specified Github repository. 
- Minimalistic, light-weight platform landing zone for connectivity, governance, monitoring and shared resources. 
- Hub/Spoke network topology, with hub VNet providing a centralized connectivity for workload spoke VNet peering. 
- IaC Backend Vending.
  - Dedicated IaC subscription to contain remote Terraform states for all deployments, with per-project backends.
  - Each project backend is configured using an **IaC Backend Vending** module to create storage and Github resources. 
  - Azure Blob Container held in the IaC subscription. 
  - Creates a Github repository environment, with target resource Azure subscription stored in environment secrets.  

### Cloudflare

- Domain registrar and DNS provider for personal domain names. 
- DNS zones updated using Terraform resources. 

### Github + Actions

- Houses the overall project and providing code repository. 
- Github Actions for automating deployments via workflows. 
- Utilizing both top-level repository and environment variables/secrets for specific workloads. 

## :hammer_and_wrench: Deployment Tool Set

- **[Terraform](https://www.terraform.io/)**
  - Provider agnostic IaC tool, free to use, plenty of discussion, guides and support available. 
  - Used to provision Proxmox infrastructre using the [BGP](https://registry.terraform.io/providers/bpg/proxmox/latest) provider. 
  - Deploy and configure on-prem and cloud resources using dedicated providers. 
  - Other considerations: Pulumi, OpenTofu. 
- **Github Actions: Self-hosted Runners**
  - Extends Github Actions workflows to allow management of on-prem environments. 
  - Can be run on a dedicated VM within Proxmox. 
- **Bash/Powershell**
  - Bootstrapping and misc utility scripts. 

## :memo: To Do

- [ ] Configure IaC for SWA remote state and GHA workflow. 
- [ ] Configure logging for hub networking to Log Analytics Workspace. 
- [ ] Migrate workloads to this code base. 
- [ ] Investigate on-prem connectivity (VPN Gateway?). 
- [ ] Investigate low-cost compute and serverless offerings in Azure. 
