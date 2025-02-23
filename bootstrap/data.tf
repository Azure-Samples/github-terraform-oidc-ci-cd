data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "github_organization" "this" {
  name = var.organization_name
}
