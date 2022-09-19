resource "azurerm_redis_cache" "main" {
  name                = "${var.project_name}-Redis"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 0
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  tags = local.default_tags
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-db"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  capabilities {
    name = "EnableServerless"
  }

  geo_location {
    location = azurerm_resource_group.main.location

    failover_priority = 0
  }

  tags = local.default_tags
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "web53"
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = "web53"
  resource_group_name   = azurerm_cosmosdb_account.main.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = "/name"
  partition_key_version = 1
}
