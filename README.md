---
page_type: sample
languages:
- terraform
- hcl
- yaml
name: Using GitHub Actions Workload identity federation (OIDC) with Azure for Terraform Deployments
description: A sample showing how to configure GitHub Workload identity federation  (OIDC) connection to Azure with Terraform and then use that configuration to deploy resources with Terraform. The sample also demonstrates bootstrapping CI / CD with Terraform and how to implement a number of best practices.
products:
- azure
- github
urlFragment: github-terraform-oidc-ci-cd
---

# Using GitHub Actions Workload identity federation (OIDC) with Azure for Terraform Deployments

This is a two part sample. The first part demonstrates how to configure Azure and GitHub for OIDC ready for Terraform deployments. The second part demonstrates an end to end Continuous Delivery Pipeline for Terraform.

## Content

| File/folder | Description |
|-------------|-------------|
| `bootstrap` | The Terraform to configure Azure and GitHub ready for Workload identity federation (OIDC) or Managed Identity authentication. |
| `example-module` | Some Terraform with Azure Resources for the demo to deploy. |
| `workflows` | The templated GitHub Actions for the demo. |
| `.gitignore` | Define what to ignore at commit time. |
| `CHANGELOG.md` | List of changes to the sample. |
| `CONTRIBUTING.md` | Guidelines for contributing to the sample. |
| `README.md` | This README file. |
| `LICENSE.md` | The license for the sample. |

## Features

This sample includes the following features:

* Setup 6 Azure User Assigned Managed Identities with Federation ready for GitHub Workload identity federation (OIDC).
* Setup an Azure Storage Account for State file management.
* Setup GitHub repository and environments ready to deploy Terraform with Workload identity federation (OIDC).
* Run a Continuous Delivery pipeline for Terraform using Workload identity federation (OIDC) auth for state and deploying resources to Azure.
* Run a Pull Request workflow with some basic static analysis.

## Getting Started

### Prerequisites

- HashiCorp Terraform CLI: [Download](https://www.terraform.io/downloads)
- Azure CLI: [Download](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update)
- An Azure Subscription: [Free Account](https://azure.microsoft.com/en-gb/free/search/)
- A GitHub Organization: [Free Organization](https://github.com/organizations/plan)

> NOTE! A GitHub personal org is not supported, you must create a full GitHub org. A free one works fine, no licensing is required for this this lab.

### Installation

- Clone the repository locally and then follow the Demo / Lab.

### Quickstart

The instructions for this sample are in the form of a Lab. Follow along with them to get up and running.

## Demo / Lab

### Lab overview

This lab has the following phases:

1. Bootstrap Azure and GitHub for Terraform CI / CD.
1. Run the Continuous Delivery pipeline for Terraform.
1. Make a change and submit a Pull Request and see the CI pipeline run.

### Bootstrap Overview and Best Practices

This demo lab creates and is scoped to resource groups. This is to ensure the lab only requires a single subscription and can be run by anyone without the overhead of creating multiple subscriptions. However, for a production scenario we recommend scoping to subscriptions and using [subscription demoncratization](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-principles#subscription-democratization).

The bootstrap implements a number of best practices for Terraform in Azure DevOps that you should take note of as you run through the lab:

- Governed pipelines: The pipelines are stored in a separate repository to the code they deploy. This allows you to govern the pipelines and ensure that only approved templates are used. This is enforced by the required template (`job_workflow_ref`) claim on the federated credentials.
- Approvals: The production environment requires approval to apply to it. This is enforced on the prod-apply environment as GitHub only supports approvals on environments.
- Concurrent locks: The actions are locked using a concurrency setting to prevent parallel deployments from running at the same time. The pipeline includes the `concurrency: <storage container>` setting to ensure that the pipeline will wait for the lock to be released before running, so it queues rather just failing.
- Workload Identity Federation (OIDC): The User Assigned Managed Identities are configured to use Workload Identity Federation (OIDC) authenticate to Azure. This means that you don't need to store any secrets in GitHub.
- Pipeline Stages: By default the pipeline is configured with dependencies between the environments. This means that the pipeline will run the dev stage, then the test stage and finally the prod stage. We also provide a parameter to target a specific environment to demonstrate a GitOps type approach too.
- Separate Plan and Apply Identities: The bootstrap creates separate plan and apply identities and service connections per environment. This is to implement the principal of least privilege. The plan identity has read only access to the resource group and the apply identity has contributor access to the resource group.

### Generate a PAT (Personal Access Token) in GitHub

1. Navigate to [github.com](https://github.com).
1. Login and select the account icon in the top right and then `Settings`.
1. Click `Developer settings`.
1. Click `Personal access tokens` and select `Tokens (classic)`.
1. Click `Generate new token` and select the `classic` option.
1. Type `Demo_OIDC` into the `Note` field.
1. Check these scopes:
   1. `repo`
   1. `workflow`
   1. `admin:org`
   1. `user`: `read:user`
   1. `user`: `user:email`
   1. `delete_repo`
1. Click `Generate token`
1. > IMPORTANT: Copy the token and save it somewhere.

### Clone the repo and setup your variables

1. Clone this repository to your local machine.
1. Open the repo in Visual Studio Code. (Hint: In a terminal you can open Visual Studio Code by navigating to the folder and running `code .`).
1. Navigate to the `bootstrap` folder and create a new file called `terraform.tfvars`.
1. In the config file add the following:

   ```terraform
    location          = "<azure_location>"
    organization_name = "<your_github_organisation_name>"
    # You can omit this is you don't want to demo approvals on the production environment. Remove this whole approvers block to omit.
    approvers = {
      user1 = "<your_azure_devops_username>"
    }  
    ```

    e.g.

    ```terraform
    location          = "uksouth"
    organization_name = "my-organization"
    approvers = {
      user1 = "demouser@example.com"
    }
    ```

    If you wish to use Microsoft-hosted agents and public networking add this setting to `terraform.tfvars`:

    ```terraform
    use_self_hosted_agents = false
    ```

    If you wish to use Container Apps (scale to zero) add this setting to `terraform.tfvars`:

    >NOTE: Container App takes longer to provision than Container Instances.

    ```terraform
    self_hosted_agent_type = "azure_container_app"
    ```

### Apply the Terraform

1. Open the Visual Studio Code Terminal and navigate the `bootstrap` folder.
1. Run `az login -T "<tenant_id>"` and follow the prompts to login to Azure with your account.
1. Run `az account show`. If you are not connected to you test subscription, change it by running `az account set --subscription "<subscription-id>"`
1. Run `$env:ARM_SUBSCRIPTION_ID = $(az account show --query id -o tsv)` to set the subscription id required by azurerm provider v4.
1. Run `$env:TF_VAR_personal_access_token = "<your_pat>"` to set the PAT you generated earlier.
1. Run `terraform init`.
1. Run `terraform plan -out tfplan`.
1. The plan will complete. Review the plan and see what is going to be created.
1. Run `terraform apply tfplan`.
1. Wait for the apply to complete.
1. You will see three outputs from this run. These are the Service Principal Ids that you will require in the next step. Save them somewhere.


### Check what has been created

#### User Assigned Managed Identity

1. Login to the [Azure Portal](https://portal.azure.com) with your Global Administrator account.
1. Navigate to your Subscription and select `Resource groups`.
1. Click the resource group with `identity` (e.g. `rg-demg-identity-mgt-uksouth-001`).
1. You should see 6 newly created User Assigned Managed Identities, 2 per environment.
1. Look for a `Managed Identity` resource post-fixed with `dev-plan` and click it.

#### Federated Credentials
1. Click on `Federated Credentials`.
1. There should only be one credential in the list, select that and take a look at the configuration.
1. Examine the `Subject identifier` and ensure you understand how it is built up.

#### Resource Group and permissions

1. Navigate to your Subscription and select `Resource groups`.
1. You should see four newly created resource groups.
1. Click the resource group with `env-dev` (e.g. `rg-demg-env-dev-uksouth-001`).
1. Select `Access control (IAM)` and select `Role assignments`.
1. Under the `Reader` role, you should see that your `dev-plan` Managed Identity has been granted access directly to the resource group.
1. Under the `Contributor` role, you should see that your `dev-apply` Managed Identity has been granted access directly to the resource group.

#### State storage account

1. Navigate to your Subscription and select `Resource groups`.
1. Click the resource group with `state` (e.g. `rg-demg-state-mgt-uksouth-001`).
1. You should see a single storage account in there, click on it.
1. Select `Containers`. You should see a `dev`, `test` and `prod` container.
1. Select the `dev` container.
1. Click `Access Control (IAM)` and select `Role assignments`.
1. Scroll down to `Storage Blob Data Owner`. You should see your `dev-plan` and `dev-apply` Managed Identities have been assigned that role.

#### GitHub Repository

1. Open github.com (login if you need to).
1. Navigate to your organization and select `Repositories`.
1. You should see a newly created repository in there (e.g. `demg-mgt-main`). Click on it.
1. You should see some files under source control.

#### GitHub Template Repository

1. Navigate to your organization and select `Repositories`.
1. You should see a newly created repository in there (e.g. `demg-mgt-templates`). Click on it.
1. You should see some files under source control.

#### GitHub environments

1. Navigate to your organization and select `Repositories`.
1. You should see a newly created repository in there (e.g. `demg-mgt-main`). Click on it.
1. You should see some files under source control.
1. Navigate to `Settings`, then select `Environments`.
1. You should see 6 environments called `dev-plan`, `dev-apply`, `test-plan`, `test-apply`, `prod-plan`, and `prod-apply`.
1. Click on the `dev-plan` environment.
1. You should see that the environment has 7 Environment variables. These secrets are all used in the Action for deploying Terraform.
1. Click on the `prod-apply` environment and take a look at the approval settings.

#### GitHub Runners (self hosted runners option only)

1. Navigate to `Settings`.
1. Click `Action` and then `Runners`.
1. You should see 4 runners ready to accept runs. (You may not see any if you chose the Container Apps option, as they are created on demand).

#### GitHub Actions

1. Navigate to `Code`.
1. Select `.github`, `workflows` and open the `ci.yml` file.
1. Examine the file and ensure you understand all the steps in there.
1. Select `.github`, `workflows` and open the `cd.yml` file.
1. Examine the file and ensure you understand all the steps in there.

### Run the Action

1. Select `Actions`, then click on the `02 - Continuous Delivery` action in the left menu.
1. Click the `Run workflow` drop-down and hit the `Run workflow` button.
1. Wait for the run to appear or refresh the screen, then click on the run to see the details.
1. You will see each environment being deployed one after the other.
1. You'll be prompted from approval fro the prod apply job.
1. Drill into the log for one of the environments and look at the `Terraform Apply` step. You should see the output of the plan and apply.
1. Run the workflow again and take a look at the log to compare what happens on the Day 2 run.

### Submit a PR

1. Clone your new repository and open it in Visual Studio Code.
1. Create a new branch, call it whatever you want.
1. Open the `config/dev.tfvars` file.
1. Add a new tag:

    ```terraform
    tags = {
      deployed_by = "terraform"
      environment = "dev"
      owner       = "Fred Bloggs"
    }
    ```

1. Commit and push the change.
1. Raise a pull request.
1. You'll see the GitHub Action running in the pull request.
1. The `Terraform Format Check` step will fail for `main.tf`. Fix it, commit and push your change.
1. Wait for the Action to run again.
1. Examine the `Terraform Plan Check` step and see what is going to be changed.
1. Merge the Pull Request.
1. Navigate to `Actions` and watch the run.

### Clean up

1. Run `terraform destroy` in the `bootstrap` folder to clean up the resources created by the bootstrap.

>NOTE: The destroy may fail the first time due to dependency between service connections and federated credentials. If this happens, run `terraform destroy` again and it should succeed.

## Resources

- [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [Terraform azurerm provider OIDC configuration](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)
- [GitHub OIDC Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers)
- [Azure External Identity Docs](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp)
