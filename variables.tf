variable "resource_group_name" {
  description = "Resource group containing (or that will contain) the storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name. Must be globally unique, 3-24 chars, lowercase letters and numbers only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account names must be 3-24 characters of lowercase letters and numbers."
  }
}

variable "create_storage_account" {
  description = "Create the storage account. Set to false to upload into an existing account."
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region for the storage account. Only used when create_storage_account is true."
  type        = string
  default     = "eastus"
}

variable "replication_type" {
  description = "Replication type for the storage account (LRS, GRS, ZRS, RAGRS). Only used when create_storage_account is true."
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "Container to upload files into. Ignored when enable_static_website is true (the $web container is used instead)."
  type        = string
  default     = "content"
}

variable "create_container" {
  description = "Create the container. Set to false to upload into an existing container."
  type        = bool
  default     = true
}

variable "container_access_type" {
  description = "Access level for a created container: private, blob, or container."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "blob", "container"], var.container_access_type)
    error_message = "container_access_type must be one of: private, blob, container."
  }
}

variable "source_dir" {
  description = "Local directory whose contents will be uploaded. Relative paths within it are preserved as blob names."
  type        = string
}

variable "file_pattern" {
  description = "Glob pattern (relative to source_dir) selecting which files to upload. '**' uploads everything recursively."
  type        = string
  default     = "**"
}

variable "enable_static_website" {
  description = "Enable static website hosting and upload files to the $web container. Requires create_storage_account = true."
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Index document for static website hosting."
  type        = string
  default     = "index.html"
}

variable "error_404_document" {
  description = "404 error document for static website hosting."
  type        = string
  default     = "404.html"
}

variable "skip_provider_registration" {
  description = "Skip automatic registration of Azure resource providers. Useful in restricted/lab environments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
