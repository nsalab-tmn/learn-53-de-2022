resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-Network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.default_tags
}

resource "azurerm_subnet" "public" {
  name                 = "${var.project_name}-Public"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name                 = "${var.project_name}-Private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.project_name}-AppGW-IP"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  domain_name_label   = "${var.project_name}-${random_string.lower.result}"

  tags = local.default_tags
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.main.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.main.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.main.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.main.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.main.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.main.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.main.name}-rdrcfg"
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-AppGW"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  enable_http2 = true

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    max_capacity = 2
    min_capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.public.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  tags = local.default_tags
}

resource "azurerm_network_security_group" "app" {
  name                = "${var.project_name}-SGApp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule = [
    {
      access                                     = "Allow"
      description                                = "Allow 8080 from public subnet"
      destination_address_prefix                 = "*"
      destination_address_prefixes               = []
      destination_application_security_group_ids = []
      destination_port_range                     = "8080"
      destination_port_ranges                    = []
      direction                                  = "Inbound"
      name                                       = "Port_8080"
      priority                                   = 100
      protocol                                   = "TCP"
      source_address_prefix                      = "*"
      source_address_prefixes                    = []
      source_application_security_group_ids      = []
      source_port_range                          = "*"
      source_port_ranges                         = []
    },
  ]
  tags = local.default_tags
}

resource "azurerm_network_security_group" "lb" {
  name                = "${var.project_name}-SGLB"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule = [
    {
      access                                     = "Allow"
      description                                = "Allow 80 from the Internet"
      destination_address_prefix                 = "*"
      destination_address_prefixes               = []
      destination_application_security_group_ids = []
      destination_port_range                     = "80"
      destination_port_ranges                    = []
      direction                                  = "Inbound"
      name                                       = "Port_80"
      priority                                   = 100
      protocol                                   = "TCP"
      source_address_prefix                      = "*"
      source_address_prefixes                    = []
      source_application_security_group_ids      = []
      source_port_range                          = "*"
      source_port_ranges                         = []
    },
  ]
  tags = local.default_tags
}

output "app_gateway_fqdn" {
  value = azurerm_public_ip.appgw.fqdn
}
