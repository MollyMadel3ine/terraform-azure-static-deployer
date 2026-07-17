terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend values are supplied at init time:
  #   terraform init -backend-config=backend.hcl
  # See backend.hcl.example. Remove this block if using as a child module.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  skip_provider_registration = var.skip_provider_registration
}

# ---------------------------------------------------------------------------
# Storage account: create one, or look up an existing one
# ---------------------------------------------------------------------------

data "azurerm_storage_account" "existing" {
  count               = var.create_storage_account ? 0 : 1
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_storage_account" "this" {
  count                    = var.create_storage_account ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type

  dynamic "static_website" {
    for_each = var.enable_static_website ? [1] : []
    content {
      index_document     = var.index_document
      error_404_document = var.error_404_document
    }
  }

  tags = var.tags
}

locals {
  storage_account_name = var.create_storage_account ? azurerm_storage_account.this[0].name : data.azurerm_storage_account.existing[0].name

  # Static website hosting requires uploading into the special $web container.
  container_name = var.enable_static_website ? "$web" : var.container_name
}

# ---------------------------------------------------------------------------
# Container: create one, unless using $web (created automatically) or reusing
# an existing container
# ---------------------------------------------------------------------------

resource "azurerm_storage_container" "this" {
  count                 = var.create_container && !var.enable_static_website ? 1 : 0
  name                  = var.container_name
  storage_account_name  = local.storage_account_name
  container_access_type = var.container_access_type
}

# ---------------------------------------------------------------------------
# Upload every file in source_dir, preserving relative paths
# ---------------------------------------------------------------------------

locals {
  files = fileset(var.source_dir, var.file_pattern)

  # Map file extensions to MIME types so browsers render content correctly.
  mime_types = {
    ".html"  = "text/html"
    ".htm"   = "text/html"
    ".css"   = "text/css"
    ".js"    = "application/javascript"
    ".mjs"   = "application/javascript"
    ".json"  = "application/json"
    ".xml"   = "application/xml"
    ".txt"   = "text/plain"
    ".md"    = "text/markdown"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".gif"   = "image/gif"
    ".svg"   = "image/svg+xml"
    ".webp"  = "image/webp"
    ".ico"   = "image/x-icon"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".ttf"   = "font/ttf"
    ".otf"   = "font/otf"
    ".pdf"   = "application/pdf"
    ".map"   = "application/json"
    ".wasm"  = "application/wasm"
  }
}

resource "azurerm_storage_blob" "files" {
  for_each = local.files

  name                   = each.value
  storage_account_name   = local.storage_account_name
  storage_container_name = local.container_name
  type                   = "Block"
  source                 = "${var.source_dir}/${each.value}"

  # Re-upload when file contents change, not just when the path changes.
  content_md5 = filemd5("${var.source_dir}/${each.value}")

  content_type = lookup(
    local.mime_types,
    lower(regex("\\.[^.]*$|$", each.value)),
    "application/octet-stream"
  )

  depends_on = [azurerm_storage_container.this]
}
