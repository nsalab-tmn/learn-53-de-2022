terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.82.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  default_tags = {
    Environment = "Rnd"
    Owner       = "Ivakin Polikasov"
    Project     = "Web-53"
    Reason      = "Apply web53 project to the Azure"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-web53"
  location = var.location

  lifecycle {
    prevent_destroy = true
  }

  tags = local.default_tags
}

resource "random_string" "lower" {
  length  = 6
  upper   = false
  lower   = true
  number  = false
  special = false
}

variable "project_name" {
  type        = string
  description = "Project name: "
  default     = "web53"
}

variable "location" {
  type        = string
  description = "Azure region: "
  default     = "West US 2"
}
