terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-lab-01"
  location = "westus"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-tf-lab-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Allow SSH inbound (you can lock this down to your IP later)
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

output "rg_name"  { value = azurerm_resource_group.rg.name }
output "nsg_name" { value = azurerm_network_security_group.nsg.name }
