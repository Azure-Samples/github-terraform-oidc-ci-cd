locals {
  approvers = [for user in data.github_organization.this.users : {
    login = user.login
    email = user.email
  } if contains(values(var.approvers), user.email)]
  invalid_approvers = setsubtract(values(var.approvers), local.approvers.*.email)
}

resource "github_team" "this" {
  name        = local.resource_names.team_name
  description = "Approvers for the Landing Zone Terraform Apply"
  privacy     = "closed"
}

resource "github_team_membership" "this" {
  for_each = { for approver in local.approvers : approver.login => approver }
  team_id  = github_team.this.id
  username = each.value.login
  role     = "member"

  lifecycle {
    precondition {
      condition     = length(local.invalid_approvers) == 0
      error_message = "At least one approver has not been supplied with a valid email. Invalid approvers: ${join(", ", local.invalid_approvers)}"
    }
  }
}

resource "github_team_repository" "this" {
  team_id    = github_team.this.id
  repository = github_repository.this.name
  permission = "push"
}
