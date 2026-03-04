
# Name of Project: Azure - Terraform - Gitlab CI/CD Pipeline Project

## Issue: 
- Save hours and replace manual tasks of clicking around Azure console to create Azure infrastructure

## End Goal:
- Automate Azure Infrastructure provisioning using Terraform Infrastructure as Code in a Gitlab CI/CD Pipeline. Be able to quickly provision and destroy resources for Cloud Security team instead.

## Prerequisites
- Gitlab Project
- 4 terraform files
- - main.tf
  - providers. tf
  - variables.tf
  - tfvars.tf
- App Registration in Entra ID (acts as the identity that is deploying the Azure resources)
- Gitlab yaml file

## Repository Structure

```
├── .gitlab-ci.yml       # CI/CD pipeline definition
├── terraform/
│   ├── main.tf          # Core infrastructure resources
│   ├── providers.tf     # Terraform and provider configuration
│   ├── variables.tf     # Input variable declarations
│   └── variables.tfvars # Variable values for deployment
```

---

## File Descriptions

### `providers.tf`
Defines the Terraform version requirements, required providers, and backend configuration.

- **azurerm** (`~> 3.0.2`) — The HashiCorp Azure Resource Manager provider used to create and manage Azure resources such as virtual machines, virtual networks, and SQL servers.
- **azuread** (`~> 3.0`) — The HashiCorp Azure Active Directory provider used to manage Azure AD resources such as users, groups, and service principals.
- **Backend (HTTP)** — Configures GitLab's built-in Terraform state storage. The state file tracks what infrastructure Terraform has deployed so it can calculate what needs to change on each run. Authentication to the backend is handled via `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD` environment variables set in the CI/CD pipeline.
- **Key Vault features** — Configures soft delete purge behavior for Azure Key Vaults on destroy.

### `variables.tf`
Declares all input variables that the Terraform configuration accepts. This file defines the variable names, types, descriptions, and optional default values — but not the actual values themselves.

| Variable | Type | Description | Default |
|---|---|---|---|
| `prefix` | string | Prefix applied to all resource names | none |
| `location` | string | Azure region where resources are deployed | `eastus` |

### `variables.tfvars`
Supplies the actual values for the variables declared in `variables.tf`. This file is passed to Terraform commands using the `-var-file=variables.tfvars` flag in the pipeline.

| Variable | Value |
|---|---|
| `prefix` | `storm` |
| `location` | `eastus2` |

> **Note:** The `location` value in `variables.tfvars` (`eastus2`) overrides the default value defined in `variables.tf` (`eastus`).

### `main.tf`
Contains all the Azure infrastructure resource definitions. Resources reference the input variables using `var.prefix` and `var.location` so that all resource names and locations are consistent and easy to change. Resources defined here include virtual networks, subnets, network security groups, network interfaces, virtual machines, and any other Azure services being provisioned.

---

## How the Files Work Together

```
variables.tfvars        →    variables.tf         →    main.tf
(actual values)              (variable declarations)    (resource definitions)
prefix = "storm"             variable "prefix" {}       name = "${var.prefix}-vm"
location = "eastus2"         variable "location" {}     location = var.location

                        providers.tf
                        (tells Terraform which providers and version to use,
                         and where to store the state file)
```

1. **`providers.tf`** is loaded first — Terraform downloads the required provider plugins (azurerm, azuread) and connects to the GitLab remote state backend.
2. **`variables.tf`** declares what inputs the configuration accepts.
3. **`variables.tfvars`** supplies the values for those inputs.
4. **`main.tf`** uses those values to define and name every Azure resource being deployed.

---

# CI/CD Pipeline is defined in the Gitlab YAML file
### What is the Gitlab YAML file?
- Gitlab YAML file is the CI/CD pipeline definition
- NOTE: Our gitlab yaml file will contain 2 pipelines:
- - Feature branch MR pipeline
- - Main pipeline


<img width="1231" height="534" alt="image" src="https://github.com/user-attachments/assets/8523738e-1170-4f0a-922b-c913376bea08" />


### The pipeline enforces a safe deployment flow using GitLab's merge request process:
Note: 
1. When you make changes in the Gitlab IDE, you have to create a new branch and then commmit. Name it feature/whatever-you-add-or-change
2. Go to Merge Request and create a Merge Request for your Feature. Then follow below steps.

```
Open Merge Request
        ↓
init + plan run automatically    ← review what will change before merging
        ↓
MR is reviewed and merged to main
        ↓
init + plan run again on main
        ↓
Maintainer clicks ▶ on review gate
        ↓
apply runs                       ← real infrastructure changes happen
```

### Pipeline Stages

| Stage | Runs On | Description |
|---|---|---|
| `init` | MR + main | Initializes Terraform and connects to remote state |
| `plan` | MR + main | Calculates and previews infrastructure changes |
| `review` | main only | Manual gate — maintainer must approve before apply |
| `apply` | main only | Applies the approved plan to Azure |
| `destroy` | main only | Tears down infrastructure (manual trigger only) |

---

## Required CI/CD Variables

The following variables must be configured in **Settings → CI/CD → Variables**:

IMPORTANT: If your variables in Gitlab are protected, then your Feature branch and Main branch must also be protected.

| Variable | Description |
|---|---|
| `GITLAB_ACCESS_TOKEN` | GitLab personal access token for Terraform remote state authentication |
| `ARM_CLIENT_ID` | Azure Service Principal App ID |
| `ARM_CLIENT_SECRET` | Azure Service Principal password |
| `ARM_TENANT_ID` | Azure Active Directory Tenant ID |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID |

> All variables should be **masked**. Variables must be available on both protected (`main`) and feature branches for the pipeline to authenticate correctly.

