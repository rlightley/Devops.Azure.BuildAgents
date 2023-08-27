
variable "location" {
  description = "Resource location"
  default     = "ukSouth"
}

variable "location_short" {
  description = "Resource location"
  default     = "uks"
}

variable "project_name" {
  description = "Project name"
  default     = "devops"
}

variable "environment" {
  description = "Name of environment to deploy to"
  default     = "shared"
}

variable "azurecaf_naming_convention" {
  description = "https://registry.terraform.io/providers/aztfmod/azurecaf/latest/docs/resources/azurecaf_naming_convention"
  default     = "cafclassic"
}
