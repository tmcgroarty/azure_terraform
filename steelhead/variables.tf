variable "vm_name" { type = string }
variable "admin_username" { type = string }

# Set via env var (interactive prompt in shell):
#   export TF_VAR_admin_password="..."
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "rg_name"   { type = string }
variable "location"  { type = string }

variable "vnet_name" { type = string }
variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_name" { type = string }
variable "subnet_prefixes" {
  type = list(string)
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "data_disk_size_gb" {
  type    = number
  default = 430
}
