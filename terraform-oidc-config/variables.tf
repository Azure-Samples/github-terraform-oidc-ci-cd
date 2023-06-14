variable "prefix" {
  type    = string
  default = "github-oidc-demo"
}

variable "location" {
  type    = string
  default = "UK South"
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "github_organisation_target" {
  type    = string
  default = "my_organisation"
}

variable "github_organisation_template" {
  type    = string
  default = "Azure-Samples"
}

variable "github_repository_template" {
  type    = string
  default = "github-terraform-oidc-ci-cd"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "test", "prod"]
}

variable "use_managed_identity" {
  type    = bool
  default = true
  description = "If selected, this option will create and configure a user assigned managed identity in the subscription instead of an AzureAD service principal."
}