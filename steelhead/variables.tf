variable "name_prefix" {
  type        = string
  description = "Short prefix for names (e.g., tim)"
}

variable "vm_base_name" {
  type        = string
  description = "Base name (e.g., sh01)"
}

variable "location" {
  type = string
}

variable "admin_username" {
  type = string
}

# Set via env var: TF_VAR_admin_password
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.50.0.0/16"]
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["10.50.1.0/24"]
}

variable "data_disk_size_gb" {
  type    = number
  default = 430
}
