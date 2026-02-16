vm_name        = "SH01"
admin_username = "azureadmin"

rg_name        = "tim-group"
location       = "westus"

# New VNet
vnet_name          = "sh01-vnet"
vnet_address_space = ["10.50.0.0/16"]

subnet_name      = "sh01-subnet"
subnet_prefixes  = ["10.50.1.0/24"]

vm_size = "Standard_D4s_v5"
data_disk_size_gb = 430
