name_prefix   = "tim"
vm_base_name  = "sh01"

location      = "westus"

admin_username = "azureadmin"

vm_size = "Standard_D4s_v5"

# optional to change
vnet_address_space = ["10.50.0.0/16"]
subnet_prefixes    = ["10.50.1.0/24"]

data_disk_size_gb  = 430
