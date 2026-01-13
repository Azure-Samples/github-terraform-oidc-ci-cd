locals {
  free_plan       = "free"
  enterprise_plan = "enterprise"
}

resource "github_repository" "this" {
  name                 = local.resource_names.repository_main_name
  description          = local.resource_names.repository_main_name
  auto_init            = true
  visibility           = data.github_organization.this.plan == local.free_plan ? "public" : "private"
  allow_update_branch  = true
  allow_merge_commit   = false
  allow_rebase_merge   = false
  vulnerability_alerts = true
}

resource "github_actions_repository_oidc_subject_claim_customization_template" "this" {
  repository         = github_repository.this.name
  use_default        = false
  include_claim_keys = ["repository_owner_id", "repository_id", "environment", "job_workflow_ref"]
}

resource "github_repository" "template" {
  name                 = local.resource_names.repository_template_name
  description          = local.resource_names.repository_template_name
  auto_init            = true
  visibility           = data.github_organization.this.plan == local.free_plan ? "public" : "private"
  allow_update_branch  = true
  allow_merge_commit   = false
  allow_rebase_merge   = false
  vulnerability_alerts = true
}

resource "github_branch_protection" "this" {
  depends_on                      = [github_repository_file.this]
  repository_id                   = github_repository.this.name
  pattern                         = "main"
  enforce_admins                  = true
  required_linear_history         = true
  require_conversation_resolution = true

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    restrict_dismissals             = true
    required_approving_review_count = length(var.approvers) > 1 ? 1 : 0
  }
}

resource "github_branch_protection" "template" {
  depends_on                      = [github_repository_file.template]
  repository_id                   = github_repository.template.name
  pattern                         = "main"
  enforce_admins                  = true
  required_linear_history         = true
  require_conversation_resolution = true

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    restrict_dismissals             = true
    required_approving_review_count = length(var.approvers) > 1 ? 1 : 0
  }
}

resource "github_actions_repository_access_level" "this" {
  count        = data.github_organization.this.plan == local.enterprise_plan ? 1 : 0
  access_level = "organization"
  repository   = github_repository.template.name
}
