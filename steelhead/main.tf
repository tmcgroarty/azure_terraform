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
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_prefixes
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
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
  name                = var.vm_name
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
  name                 = "${var.vm_name}-data-430g"
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

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
