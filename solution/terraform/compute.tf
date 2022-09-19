resource "azurerm_virtual_machine_scale_set" "main" {
  name                = "${var.project_name}-ScaleSet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  upgrade_policy_mode = "Automatic"
  zones               = ["1", "2"]

  #single_placement_group = true
  #overprovision = false

  network_profile {
    name    = "AppNetworkProfile"
    primary = true

    ip_configuration {
      name                                         = "IPConfiguration"
      subnet_id                                    = azurerm_subnet.private.id
      application_gateway_backend_address_pool_ids = azurerm_application_gateway.main.backend_address_pool.*.id
      primary                                      = true
    }
    network_security_group_id = azurerm_network_security_group.app.id
  }

  sku {
    name     = "Standard_B1s"
    tier     = "Standard"
    capacity = 1
  }

  storage_profile_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name_prefix = var.project_name
    admin_username       = "web53"
    custom_data = templatefile("files/init.sh", {
      key  = file("files/deploy.pem"),
      repo = "git@github.com:polikasov/Cloud53-Task-1.git",
      env_file = templatefile("files/env.yaml", {
        redis_host       = azurerm_redis_cache.main.hostname,
        redis_secret     = azurerm_redis_cache.main.primary_access_key,
        cosmos_host      = azurerm_cosmosdb_account.main.endpoint,
        cosmos_secret    = azurerm_cosmosdb_account.main.primary_key,
        cosmos_db_name   = "web53",
        cosmos_container = "web53"
      })
    })
  }

  os_profile_linux_config {
    ssh_keys {
      key_data = file("./files/id_rsa.pub")
      path     = "/home/web53/.ssh/authorized_keys"
    }
    disable_password_authentication = true
  }

  tags = local.default_tags
}

resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "${var.project_name}-AutoScale"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  target_resource_id  = azurerm_virtual_machine_scale_set.main.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 4
    }

    rule {
      metric_trigger {
        metric_name              = "AvgRequestCountPerHealthyHost"
        metric_resource_id       = azurerm_application_gateway.main.id
        metric_namespace         = "microsoft.network/applicationgateways"
        time_grain               = "PT2M"
        statistic                = "Average"
        time_window              = "PT2M"
        time_aggregation         = "Average"
        operator                 = "GreaterThan"
        threshold                = 20
        divide_by_instance_count = false
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT2M"
      }
    }

    rule {
      metric_trigger {
        metric_name              = "AvgRequestCountPerHealthyHost"
        metric_resource_id       = azurerm_application_gateway.main.id
        metric_namespace         = "microsoft.network/applicationgateways"
        time_grain               = "PT2M"
        statistic                = "Average"
        time_window              = "PT2M"
        time_aggregation         = "Average"
        operator                 = "LessThan"
        threshold                = 20
        divide_by_instance_count = false
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT2M"
      }
    }
  }

  tags = local.default_tags
}
