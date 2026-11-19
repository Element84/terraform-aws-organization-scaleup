terraform {
  required_version = ">= 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend blocks cannot use variables.
  # TODO: S3 bucket names are globally unique, so change the bucket to your
  # own, and the region to match home_region.
  backend "s3" {
    bucket       = "org-core-terraform-state"
    key          = "core/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.home_region

  # prevent accidental deployment to wrong aws account
  allowed_account_ids = var.rootmgmt_account_id

  default_tags {
    tags = {
      ManagedBy = "iac"
    }
  }
}

# Assumes OrganizationAccountAccessRole into the Audit account, the delegated
# administrator for our org-wide security services. Only exercised by
# resources that already depend on the Audit account existing.
provider "aws" {
  alias  = "audit"
  region = var.home_region

  assume_role {
    role_arn     = "arn:aws:iam::${module.acct_audit.account_id}:role/${local.org_access_role}"
    session_name = "terraform-audit-setup"
  }

  default_tags {
    tags = {
      ManagedBy = "iac"
    }
  }
}
