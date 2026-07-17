output "storage_account_name" {
  description = "The storage account files were uploaded to."
  value       = local.storage_account_name
}

output "container_name" {
  description = "The container files were uploaded to."
  value       = local.container_name
}

output "uploaded_files" {
  description = "Relative paths of all uploaded files."
  value       = sort([for f in local.files : f])
}

output "file_count" {
  description = "Number of files uploaded."
  value       = length(local.files)
}

output "static_website_url" {
  description = "Primary endpoint of the static website, if enabled."
  value       = var.enable_static_website && var.create_storage_account ? azurerm_storage_account.this[0].primary_web_endpoint : null
}
