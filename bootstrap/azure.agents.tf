module "azure_devops_agents" {
  source  = "Azure/avm-ptn-cicd-agents-and-runners/azurerm"
  version = "0.3.2"

  count = var.use_self_hosted_agents ? 1 : 0

  resource_group_creation_enabled               = false
  resource_group_name                           = module.resource_group["agents"].name
  postfix                                       = lower(replace(var.postfix, "-", ""))
  location                                      = var.location
  compute_types                                 = [var.self_hosted_agent_type]
  container_instance_count                      = 4
  version_control_system_type                   = "github"
  version_control_system_personal_access_token  = var.personal_access_token
  version_control_system_organization           = var.organization_name
  version_control_system_repository             = github_repository.this.name
  virtual_network_creation_enabled              = false
  virtual_network_id                            = module.virtual_network[0].resource_id
  container_app_subnet_id                       = module.virtual_network[0].subnets["agents"].resource_id
  container_instance_subnet_id                  = module.virtual_network[0].subnets["agents"].resource_id
  container_registry_private_endpoint_subnet_id = module.virtual_network[0].subnets["private_endpoints"].resource_id
  depends_on                                    = [github_repository_file.this]
}
