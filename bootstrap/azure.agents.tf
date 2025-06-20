module "azure_devops_agents" {
  source  = "Azure/avm-ptn-cicd-agents-and-runners/azurerm"
  version = "0.4.0"

  count = var.use_self_hosted_agents ? 1 : 0

  resource_group_creation_enabled               = false
  resource_group_name                           = module.resource_group["agents"].name
  postfix                                       = local.resource_names.agent_compute_postfix_name
  container_instance_name_prefix                = local.resource_names.container_instance_prefix_name
  container_registry_name                       = local.resource_names.container_registry_name
  location                                      = var.location
  compute_types                                 = [var.self_hosted_agent_type]
  container_instance_count                      = 4
  version_control_system_type                   = "github"
  version_control_system_personal_access_token  = var.personal_access_token
  version_control_system_organization           = var.organization_name
  version_control_system_repository             = github_repository.this.name
  version_control_system_runner_group           = var.use_runner_group ? github_actions_runner_group.this[0].name : null
  version_control_system_runner_scope           = var.use_runner_group ? "org" : "repo"
  virtual_network_creation_enabled              = false
  virtual_network_id                            = module.virtual_network[0].resource_id
  container_app_subnet_id                       = module.virtual_network[0].subnets["agents"].resource_id
  container_instance_subnet_id                  = module.virtual_network[0].subnets["agents"].resource_id
  container_registry_private_endpoint_subnet_id = module.virtual_network[0].subnets["private_endpoints"].resource_id
  container_instance_use_availability_zones     = var.runner_use_availability_zones
  depends_on                                    = [github_repository_file.this]
}
