locals {
  primary_approver     = length(var.approvers) > 0 ? var.approvers[keys(var.approvers)[0]] : ""
  default_commit_email = coalesce(local.primary_approver, "demouser@example.com")

  self_hosted_runner_name = local.use_runner_group ? "group: runner-group-${var.postfix}" : "self-hosted"

  target_folder_name = ".github"

  environment_replacements = { for environment_key, environment_value in var.environments : "${format("%03s", environment_value.display_order)}-${environment_key}" => {
    name                                         = lower(replace(environment_key, "-", ""))
    display_name                                 = environment_value.display_name
    runner_name                                  = var.use_self_hosted_agents ? local.self_hosted_runner_name : "ubuntu-latest"
    environment_name_plan                        = "${environment_key}-plan"
    environment_name_apply                       = "${environment_key}-apply"
    dependent_environment                        = environment_value.dependent_environment
    backend_azure_storage_account_container_name = environment_key
  } }

  template_folder = "${path.module}/${var.example_module_path}"
  files = { for file in fileset(local.template_folder, "**") : file => {
    name    = file
    content = file("${local.template_folder}/${file}")
  } }

  pipeline_main_replacements = {
    environments                     = local.environment_replacements
    organization_name                = var.organization_name
    repository_name_templates        = github_repository.template.name
    cd_template_path                 = ".github/workflows/cd-template.yaml"
    ci_template_path                 = ".github/workflows/ci-template.yaml"
    root_module_folder_relative_path = "."
  }

  pipeline_main_folder = "${path.module}/../workflows/main"
  pipeline_main_files = { for file in fileset(local.pipeline_main_folder, "**") : "${local.target_folder_name}/${file}" => {
    name    = file
    content = templatefile("${local.pipeline_main_folder}/${file}", local.pipeline_main_replacements)
  } }

  main_repository_files = merge(local.files, local.pipeline_main_files)

  pipeline_template_replacements = {
    environments = local.environment_replacements
  }

  pipeline_template_folder = "${path.module}/../workflows/templates"
  pipeline_template_files = { for file in fileset(local.pipeline_template_folder, "**") : "${local.target_folder_name}/${file}" => {
    name    = file
    content = templatefile("${local.pipeline_template_folder}/${file}", local.pipeline_template_replacements)
  } }
}

resource "github_repository_file" "this" {
  for_each            = local.main_repository_files
  repository          = github_repository.this.name
  file                = each.key
  content             = each.value.content
  commit_author       = local.default_commit_email
  commit_email        = local.default_commit_email
  commit_message      = "Add ${each.key} [skip ci]"
  overwrite_on_create = true
}

resource "github_repository_file" "template" {
  for_each            = local.pipeline_template_files
  repository          = github_repository.template.name
  file                = each.key
  content             = each.value.content
  commit_author       = local.default_commit_email
  commit_email        = local.default_commit_email
  commit_message      = "Add ${each.key} [skip ci]"
  overwrite_on_create = true
}