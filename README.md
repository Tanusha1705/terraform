# Azure VM Infrastructure as Code (IaC) & 12-Stage CI/CD Pipeline

Production-ready modular Terraform repository and CI/CD pipeline templates for provisioning, securing, bootstrapping, protecting, and monitoring Azure Virtual Machines.

## Highlights

- **12-Stage Sequential Pipeline**:
  1. `Validate`: `terraform init` and `terraform validate`.
  2. `Format`: `terraform fmt -check -recursive`.
  3. `Plan`: Deterministic `tfplan` binary and JSON artifact generation.
  4. `Security Scan`: Shift-left analysis using `tfsec` and `checkov`.
  5. `Approval`: Environment manual approval gate (`production` environment).
  6. `Apply`: Strictly applies the approved `tfplan` artifact.
  7. `VM Extension Deployment`: Deploys Guest Agent extensions in ordered sequence.
  8. `Domain Join`: Active Directory / Entra ID domain join verification.
  9. `Software Installation`: Custom Script Extension bootstrapping (packages, tools, hardening).
  10. `Backup Enablement`: Azure Recovery Services Vault association & initial backup trigger.
  11. `Monitoring Enablement`: Azure Monitor Agent (AMA), Data Collection Rule (DCR), and Log Analytics.
  12. `Compliance Validation`: Automated tags, power state, and Azure Policy compliance audits.

- **Dual CI/CD Implementation**:
  - [azure-pipelines.yml](file:///c:/Users/home/Desktop/Terraform/azure-pipelines.yml) (Azure DevOps YAML with environments, parameters, and variable groups)
  - [.github/workflows/vm-provisioning.yml](file:///c:/Users/home/Desktop/Terraform/.github/workflows/vm-provisioning.yml) (GitHub Actions with OIDC and SARIF security integration)

- **Modular Terraform Architecture**:
  - [terraform/modules/vm](file:///c:/Users/home/Desktop/Terraform/terraform/modules/vm) (NIC, Disk, VM, OS variants)
  - [terraform/modules/extensions](file:///c:/Users/home/Desktop/Terraform/terraform/modules/extensions) (Custom Script, Domain Join, AMA, Dependency Agent)
  - [terraform/modules/backup](file:///c:/Users/home/Desktop/Terraform/terraform/modules/backup) (RSV, retention policy, protected VM)
  - [terraform/modules/monitoring](file:///c:/Users/home/Desktop/Terraform/terraform/modules/monitoring) (Log Analytics workspace, DCR, Action Groups, alerts)

- **Detailed Documentation**:
  - Full engineering architecture and troubleshooting runbook: [IMPLEMENTATION_GUIDE.md](file:///c:/Users/home/Desktop/Terraform/IMPLEMENTATION_GUIDE.md)
