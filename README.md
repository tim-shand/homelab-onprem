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
  - Generates required Terraform files, kicks off the deployment, and triggers post-deployment state migration to Azure. 
  - Creates Entra ID Service Principal, secured with Federated Credentials (OIDC), and adds details to a specified Github repository. 
- Minimalistic, light-weight platform landing zone for connectivity, governance, monitoring and shared resources. 
- Hub/Spoke network topology, with hub VNet providing a centralized connectivity for workload spoke VNet peering. 
- IaC Backend Vending.
  - Dedicated IaC subscription to contain remote Terraform states for all deployments, with per-project Azure Blob Containers. 
  - Each project backend is deployed using an IaC Backend Vending module to create storage and Github resources. 
  - Creates a Github repository environment, with target resource Azure subscription stored in environment secrets. 

### Cloudflare

- Domain registrar and DNS provider for personal domain names. 
- DNS zones updated using Terraform resources. 

### Github + Actions

- Contains the overall project and provides centralized code repository. 
- Github Actions providing CI/CD by automating deployments via workflows. 
- Utilizing both top-level repository and environment variables/secrets for specific workloads. 

## :hammer_and_wrench: Deployment Tool Set

- **[Terraform](https://www.terraform.io/)**
  - Provider agnostic IaC tool, free to use, plenty of discussion, guides and support available. 
  - Deploy and manage on-prem and cloud resources using dedicated providers. 
  - Other considerations: Pulumi, OpenTofu. 
- **Github Actions: Self-hosted Runners (PENDING)**
  - Extends Github Actions workflows to allow management of on-prem environments. 
  - Can be run on a dedicated VM within Proxmox. 
- **Bash/Powershell**
  - Bootstrapping and misc utility scripts. 

## :memo: To Do

- [ ] Setup self-hosted Github Runner on-prem. 
- [ ] Update IaC Backend vending to add target resource subscription to GH env secrets. 
- [ ] Configure logging for hub networking to Log Analytics Workspace. 
- [ ] Investigate on-prem connectivity (VPN Gateway?). 
- [ ] Investigate low-cost compute and serverless offerings in Azure. 
