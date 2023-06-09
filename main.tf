terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create a resource group
resource "azurerm_resource_group" "biliRG" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Create app service plan
resource "azurerm_service_plan" "biliAppPlan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.biliRG.name
  location            = azurerm_resource_group.biliRG.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# Create db server
resource "azurerm_mssql_server" "biliServerSql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.biliRG.name
  location                     = azurerm_resource_group.biliRG.location
  version                      = "12.0"
  administrator_login          = "admin05"
  administrator_login_password = "HNZC.BpslKg1x3+i"
}

# Create db

resource "azurerm_mssql_database" "biliDb" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.biliServerSql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false
}

#create firewall rule
resource "azurerm_mssql_firewall_rule" "biliFR" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.biliServerSql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create  TaskBoard DotNet app
resource "azurerm_linux_web_app" "biliTaskBoard" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.biliRG.name
  location            = azurerm_service_plan.biliAppPlan.location
  service_plan_id     = azurerm_service_plan.biliAppPlan.id

  site_config {
     application_stack{
	   dotnet_version="6.0"
	 }
	 always_on=false
  }
    
  connection_string{
  name = "DefaultConnection"
  type = "SQLAzure"
  value = "Data Source=tcp:${azurerm_mssql_server.biliServerSql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.biliDb.name};User ID=${azurerm_mssql_server.biliServerSql.administrator_login};Password=${azurerm_mssql_server.biliServerSql.administrator_login_password};Trusted_Connection=False;MultipleActiveResultSets=True;"
  }
}

# Deploy code from github

resource "azurerm_app_service_source_control" "biliSourceControl" {
  app_id   = azurerm_linux_web_app.biliTaskBoard.id
  repo_url = var.repo_URL
  branch   = "main"
  use_manual_integration=true
}