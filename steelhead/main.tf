terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  # Example: tim-sh01-a1b2c3
  name_prefix = "${var.name_prefix}-${var.vm_base_name}-${random_string.suffix.result}"

  rg_name     = "rg-${local.name_prefix}"
  vnet_name   = "vnet-${local.name_prefix}"
  subnet_name = "subnet-${local.name_prefix}"
  pip_name    = "pip-${local.name_prefix}"
  nic_name    = "nic-${local.name_prefix}"
  nsg_name    = "nsg-${local.name_prefix}"
  disk_name   = "disk-${local.name_prefix}-data"
  vm_name     = local.name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_prefixes
}

# (Optional but recommended) NSG for lab management
resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # LAB default: open 22/443 from anywhere. If you want to lock it down later,
  # we can switch source_address_prefix to your public IP /32.
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS" # cheap SSD
  }

  # Riverbed SteelHead Cloud RiOS 10.2.0a - x64 Gen2 (Marketplace)
  source_image_reference {
    publisher = "riverbed"
    offer     = "steelhead-cloud"
    sku       = "rios-10_2_0a-x64-gen2"
    version   = "latest"
  }

  # Required for marketplace plan images
  plan {
    publisher = "riverbed"
    product   = "steelhead-cloud"
    name      = "rios-10_2_0a-x64-gen2"
  }
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = local.disk_name
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name

  storage_account_type = "StandardSSD_LRS" # cheap SSD
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id

  lun     = 0
  caching = "ReadWrite"
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
