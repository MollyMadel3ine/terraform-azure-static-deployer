# Terraform: Azure Static Content Deployer

Upload an entire local directory to Azure Blob Storage with Terraform — optionally as a fully hosted static website. Files are discovered automatically with `fileset()`, relative paths are preserved as blob names, correct `Content-Type` headers are set by extension, and changed files are re-uploaded on the next apply thanks to `content_md5` tracking.

## Features

- **Directory upload**: everything under `source_dir` (filterable with `file_pattern`) becomes a blob, keeping its relative path.
- **Static website mode**: set `enable_static_website = true` to enable Azure's static website hosting and deploy to the `$web` container; the site URL is emitted as an output.
- **Create or reuse**: creates the storage account and container by default, or points at existing ones with `create_storage_account = false` / `create_container = false`.
- **Content-Type mapping**: HTML, CSS, JS, images, fonts, JSON, WASM and more are served with the right MIME type, falling back to `application/octet-stream`.
- **Change detection**: `content_md5` means editing a file triggers a re-upload; unchanged files are untouched.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3
- Azure credentials available to Terraform (e.g. `az login`)
- An existing resource group (and, for remote state, a state storage account/container)

## Usage

```bash
# 1. Configure remote state (backend blocks can't use variables)
cp backend.hcl.example backend.hcl   # edit with your values
terraform init -backend-config=backend.hcl

# 2. Configure inputs
cp terraform.tfvars.example terraform.tfvars   # edit with your values

# 3. Deploy
terraform plan
terraform apply
```

### Example: deploy a static website

```hcl
resource_group_name   = "my-rg"
storage_account_name  = "mysiteassets123"
source_dir            = "./site"
enable_static_website = true
```

After `apply`, the `static_website_url` output gives you the live URL.

### Example: sync files into an existing private container

```hcl
resource_group_name    = "my-rg"
storage_account_name   = "existingaccount"
create_storage_account = false
create_container       = false
container_name         = "documents"
source_dir             = "./docs"
file_pattern           = "**/*.pdf"
```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `resource_group_name` | Resource group for the storage account | (required) |
| `storage_account_name` | Globally unique storage account name | (required) |
| `source_dir` | Local directory to upload | (required) |
| `file_pattern` | Glob selecting files within `source_dir` | `**` |
| `create_storage_account` | Create the account vs. reuse existing | `true` |
| `location` | Region for a created account | `eastus` |
| `replication_type` | Replication for a created account | `LRS` |
| `enable_static_website` | Host as a static website via `$web` | `false` |
| `index_document` / `error_404_document` | Website index / 404 pages | `index.html` / `404.html` |
| `container_name` | Target container (non-website mode) | `content` |
| `create_container` | Create the container vs. reuse existing | `true` |
| `container_access_type` | Access level for a created container | `private` |
| `skip_provider_registration` | Skip Azure provider registration | `false` |
| `tags` | Tags for created resources | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `storage_account_name` | Account files were uploaded to |
| `container_name` | Container files were uploaded to |
| `uploaded_files` | Sorted list of uploaded blob names |
| `file_count` | Number of files uploaded |
| `static_website_url` | Site URL when static hosting is enabled |

## Notes and limitations

- **Deletions sync too**: because blobs are managed with `for_each`, removing a file locally removes its blob on the next apply.
- **Static website mode requires creating the account** (`create_storage_account = true`), since the `static_website` setting lives on the account resource in the azurerm 3.x provider.
- **State storage vs. content storage are independent** — keep them in separate accounts or at least separate containers; don't upload content into your `tfstate` container.
- To use this as a child module rather than a root configuration, delete the `backend "azurerm" {}` block from `main.tf` and pass variables from your calling module.
