# 

## Name of Project: Azure - Terraform - Gitlab CI/CD Pipeline Project




Issue: Save hours and replace manual tasks of clicking around Azure console to create test azure virtual machines, storage accounts, key vaults, sql servers/sql databases, managed identities, Entra ID users with role assignments, and more.

## End Goal:
Automate Azure Infrastructure provisioning using Terraform Infrastructure as Code in a Gitlab CI/CD Pipeline. Be able to quickly provision and destroy resources for Cloud Security team instead.

# How To: Deploy Azure Services via Terraform through a Gitlab CI/CD Pipeline

# Prerequisites
- Gitlab Project
- 4 terraform files
- - main.tf
  - providers. tf
  - variables.tf
  - tfvars.tf
- App Registration in Entra ID (acts as the identity that is deploying the Azure resources)

  
<img width="1727" height="814" alt="image" src="https://github.com/user-attachments/assets/680aa069-9de5-4941-8b88-ad82408f1b78" />


## Getting started

To make it easy for you to get started with GitLab, here's a list of recommended next steps.

Already a pro? Just edit this README.md and make it your own. Want to make it easy? [Use the template at the bottom](#editing-this-readme)!

## Add your files

* [Create](https://docs.gitlab.com/user/project/repository/web_editor/#create-a-file) or [upload](https://docs.gitlab.com/user/project/repository/web_editor/#upload-a-file) files
* [Add files using the command line](https://docs.gitlab.com/topics/git/add_files/#add-files-to-a-git-repository) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://gitlab.com/earkevin11-group/earkevin11-project.git
git branch -M main
git push -uf origin main
```

# Stages of my Terraform workflows
init — initialize
plan — preview changes
apply — deploy
destroy — tear down

# Why init and plan run on the MR first?
When you open a Merge Request, GitLab triggers a pipeline on your feature branch. The purpose of running init and plan at this stage is so that you and your team can review what Terraform is going to change BEFORE it gets merged to main.
Think of it like a preview:
feature branch MR pipeline
├── init  ← sets up Terraform, confirms backend connects
└── plan  ← shows exactly what will be created/changed/destroyed
You can click into the plan job logs and see output like:
+ azurerm_resource_group.rg will be created
+ azurerm_virtual_network.vnet will be created
~ azurerm_subnet.subnet will be updated
This lets you catch mistakes before they ever touch real infrastructure.

<img width="723" height="500" alt="image" src="https://github.com/user-attachments/assets/15575e08-ebd9-43df-ba4b-6d4e3c39c2c6" />


Why does plan run twice?
You might be wondering why plan runs on the MR AND again on main after merging. This is intentional and is actually best practice because:

The MR plan is for human review — did anyone else merge something while your MR was open that could conflict?
The main plan is the authoritative plan that apply actually uses
It ensures apply never runs a plan that could have drifted from what was reviewed


In short — the MR init and plan are your safety check before merging. They answer the question "is this safe to merge?" before anything touches main or real infrastructure.



volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
