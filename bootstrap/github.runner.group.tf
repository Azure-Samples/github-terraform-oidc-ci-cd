locals {
  use_runner_group = var.use_runner_group && data.github_organization.this.plan == local.enterprise_plan && var.use_self_hosted_agents
}

resource "github_actions_runner_group" "this" {
  count                   = local.use_runner_group ? 1 : 0
  name                    = local.resource_names.runner_group_name
  visibility              = "selected"
  selected_repository_ids = [github_repository.this.repo_id, github_repository.template.repo_id]
}