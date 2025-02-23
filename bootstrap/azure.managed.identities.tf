module "user_assigned_managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.3"

  for_each            = local.environment_split
  location            = var.location
  name                = "uami-${var.postfix}-${each.value.environment}-${each.value.type}"
  resource_group_name = module.resource_group["identity"].name
}

locals {
  template_claim_structure = "${var.organization_name}/${var.postfix}-demo-template/%s@refs/heads/main"

  federated_credentials = { for federated_credential in flatten([for env_key, env_value in local.environment_split : [
    for template in env_value.required_templates : {
      composite_key                     = "${env_key}-${template}"
      user_assigned_managed_identity_id = module.user_assigned_managed_identity[env_key].resource_id
      subject                           = "repo:${var.organization_name}/${var.postfix}-demo:environment:${env_value.environment}:job_workflow_ref:${format(local.template_claim_structure, template)}"
    }
  ]]) : federated_credential.composite_key => federated_credential }
}

resource "azurerm_federated_identity_credential" "this" {
  for_each            = local.federated_credentials
  parent_id           = each.value.user_assigned_managed_identity_id
  name                = "${var.organization_name}-${var.postfix}-${each.key}"
  resource_group_name = module.resource_group["identity"].name
  audience            = [local.default_audience_name]
  issuer              = local.github_issuer_url
  subject             = each.value.subject
}

