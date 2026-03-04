
# Name of Project: Azure - Terraform - Gitlab CI/CD Pipeline Project

## Issue: 
- Save hours and replace manual tasks of clicking around Azure console to create test azure virtual machines, storage accounts, key vaults, sql servers/sql databases, managed identities, Entra ID users with role assignments, and more.

## End Goal:
- Automate Azure Infrastructure provisioning using Terraform Infrastructure as Code in a Gitlab CI/CD Pipeline. Be able to quickly provision and destroy resources for Cloud Security team instead.

# How To: Deploy Azure Services via Terraform through a Gitlab CI/CD Pipeline

# Prerequisites
- Gitlab Project
- 4 terraform files
- - main.tf
  - providers. tf
  - variables.tf
  - tfvars.tf
- App Registration in Entra ID (acts as the identity that is deploying the Azure resources)
- Gitlab yaml file

# Gitlab YAML file for Real World Production CI/CD Pipeline
- I will break down how teams go through a CI/CD Pipeline and professionals avoid breaking production and reduce security risks.

# 1. Creating a new branch and commiting it. Never commit directly to the Main branch!
<img width="1259" height="895" alt="image" src="https://github.com/user-attachments/assets/50beaa75-c57f-4562-9751-337393e1fb25" />


# 2. Create a Merge Request for your feature, which triggers the feature branch MR pipeline  
<img width="1039" height="590" alt="image" src="https://github.com/user-attachments/assets/1593f20b-a023-45e5-9621-ada68f656b8d" />

# NOTE: Our gitlab yaml file will 2 pipelines:
1. Feature branch MR pipeline
2. Main pipeline

   
Feature branch MR pipeline has 2 stages:
1. init — initialize
2. plan — preview changes and shows you what will be created, changed, and destroyed


Main Pipeline has 5 stages:
1. init
2. plan
3. review (manual click)
4. apply — deploy (manual click)
5. destroy — tear down (manual click)

6. Once the MR pipeline's two jobs passes, you have to click merge, which triggers the Main pipeline 
<img width="1231" height="534" alt="image" src="https://github.com/user-attachments/assets/7f6d25a4-69f3-4858-87d6-c24361378434" />


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

## IMPORTANT: This lets you catch mistakes before they ever touch real infrastructure.

<img width="723" height="500" alt="image" src="https://github.com/user-attachments/assets/15575e08-ebd9-43df-ba4b-6d4e3c39c2c6" />



# Frequently asked questions?

## Why does plan run twice?
- MR Plan - Purpose is code review
- Main Plan - For infrastructure approval

## What could happen if you skip MR plan?
- Skipping the MR plan would mean merging blind into Main branch without knowing the impact.
- Skipping the main plan would mean applying a potentially stale plan. Both serve different purposes and both are needed.

## Is it best practice to have terraform plan in both a Merge Request pipeline and a Main pipeline?
- Yes, this is intentional and is actually best practice because it catches issues before it reaches Main pipeline.
- It is a secondary check before Terraform apply is ran in Main pipeline!
- In short — the MR init and plan are your safety check before merging. They answer the question "is this safe to merge?" before anything touches main or real infrastructure.

<img width="728" height="1098" alt="image" src="https://github.com/user-attachments/assets/005bd402-81cb-4b83-ab86-bf4aa9d8a654" />


