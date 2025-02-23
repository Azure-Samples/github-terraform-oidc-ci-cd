locals {
  apply_key = "apply"
}

resource "github_repository_environment" "this" {
  for_each    = local.environment_split
  environment = each.key
  repository  = github_repository.this.name

  dynamic "reviewers" {
    for_each = each.value.type == local.apply_key && each.value.has_approval && length(var.approvers) > 0 ? [1] : []
    content {
      teams = [
        github_team.this.id
      ]
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.type == local.apply_key ? [1] : []
    content {
      protected_branches     = true
      custom_branch_policies = false
    }
  }
}
