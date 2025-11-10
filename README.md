# Personal Home Lab

Welcome to my personal home lab! :wave:  
This project provides an environment for self-hosting and experimenting with different technologies.  
A base for hands-on learning, developing knowledge and improving skills in DevOps and Cloud platforms.  
Bootstrapped, deployed and continuously managed using Terraform and GitHub Actions workflows.  

## :office: Physical Hardware

### Hypervisors
- 2x Lenovo Think Station P330 (Intel i5 9600T, 16GB DDR4, 250GB OS, 1TB ZFS pool).
  - Running clustered [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) for VMs.
  - Raspberry Pi for maintaining Quorum [details on setup found here](https://www.tshand.com/p/home-lab-part-6-setup-qdevice-for-proxmox-quorum/).
  
### Networking
- **Switch:** TP-Link TL-SG108PE 8-Port Gigabit Easy Smart PoE Switch.
  - Connecting nodes physically, providing outbound access to Internet via firewall connected to home WiFi network.
- **Firewall:** HP EliteDesk G1 (Intel i5-4590T, 16 GB DDR3, 250 GB SSD).
  - Running [OPNsense](https://opnsense.org/) providing firewall, VLAN and routing functionality.

## :computer: Virtualized Infrastructure

- **Firewall/Router:** Virtualized [pfSense](https://www.pfsense.org/download/) VM (for internal lab use).
- **Virtual Machines:** Management servers, test and misc VMs.

## :cloud: Cloud Services

### Azure

- Configured with a light, simplified platform landing zone for connectivity and shared resources. 
- Entra ID for identity and service principal provisioning. 
- Hub/Spoke network topology, with hub VNet providing a centralalized connectivity for workload spoke VNets peering.
- This design utilizes a dedicated Azure subscription to contain the remote Terraform states for all deployments. 
- Created using during my Terraform bootstrap deployment process (_see_ `environments\azure\bootstrap` :eyes:).
- Uses a simple Terraform module to generate additional Azure resources for new project remote states. 

### Cloudflare

- Domain registrar and DNS provider for personal domain names. 
- DNS zones can be updated using Terraform resources. 

### Github + Actions

- Housing the project and providing code repository. 
- Github Actions for automation pipelines (workflows). 
- Utilizing both repository and environment specific variables/secrets in Github.
  - Requires additional environment-specific credential in Azure under `Entra ID > App Registration > Credentials & Secrets > Federated Credentials`. 

## :hammer_and_wrench: Deployment Tool Set

- **[Terraform](https://www.terraform.io/)**
  - Provider agnostic IaC tool, free to use, plenty of discussion, guides and support available.
  - Used to provision Proxmox infrastructre using the [BGP](https://registry.terraform.io/providers/bpg/proxmox/latest) provider.
  - Deploy and configure Azure and Cloudflare resources.
  - Other considerations: Pulumi, OpenTofu (planning to investigate these options further).
- **Bash/Powershell**
  - Bootstrapping and misc utility scripts.

## :memo: To Do

- [ ] Configure IaC for SWA remote state and GHA workflow. 
- [ ] Configure logging for hub networking to Log Analytics Workspace. 
- [ ] Migrate workloads to this code base. 
- [ ] Investigate on-prem connectivity (VPN Gateway?). 
- [ ] Investigate low-cost compute and serverless offerings in Azure. 
