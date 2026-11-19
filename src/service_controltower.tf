# -----------------------------------------------------------------------------
# AWS Control Tower
#
# The landing zone: Control Tower sets up organization-wide logging and AWS
# Config, applies its mandatory controls, and reports drift. Accounts are
# then created through its Account Factory (see modules/account_factory).
#
# Do not change anything Control Tower manages by hand in the console. It is
# reported as drift, and the next landing zone update may overwrite it.
# -----------------------------------------------------------------------------

locals {
  # Pinned so upgrades are deliberate. After changing the landing zone
  # version, every registered OU must be re-registered: raise
  # controltower_ou_baseline_version to the baseline AWS lists for the new
  # landing zone version.
  controltower_landing_zone_version = "4.0"
  controltower_ou_baseline_version  = "5.0"

  # ARN of AWSControlTowerBaseline, the baseline that registers an OU.
  # TODO: confirm for your home region with: aws controltower list-baselines
  controltower_ou_baseline_arn = "arn:aws:controltower:${var.home_region}::baseline/17BSJV3IGJ2QSGA2"

  # OUs that hold accounts created through Account Factory. The Security OU
  # is not listed: the landing zone governs its two accounts directly.
  controltower_registered_ous = {
    infrastructure = aws_organizations_organizational_unit.infrastructure
    workloads      = aws_organizations_organizational_unit.workloads
    sandbox        = aws_organizations_organizational_unit.sandbox
  }
}

# --- Service roles -----------------------------------------------------------

# Control Tower requires these three roles, with these exact names and path,
# to exist before a landing zone is created through the API.

data "aws_iam_policy" "controltower_service_role" {
  name = "AWSControlTowerServiceRolePolicy"
}

data "aws_iam_policy" "controltower_cloudtrail_role" {
  name = "AWSControlTowerCloudTrailRolePolicy"
}

resource "aws_iam_role" "controltower_admin" {
  name = "AWSControlTowerAdmin"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "controltower.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "controltower_admin" {
  name = "AWSControlTowerAdminPolicy"
  role = aws_iam_role.controltower_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:DescribeAvailabilityZones"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "controltower_admin" {
  role       = aws_iam_role.controltower_admin.name
  policy_arn = data.aws_iam_policy.controltower_service_role.arn
}

# CloudFormation assumes this role to deploy stack sets into member accounts.
resource "aws_iam_role" "controltower_stackset" {
  name = "AWSControlTowerStackSetRole"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudformation.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "controltower_stackset" {
  name = "AWSControlTowerStackSetRolePolicy"
  role = aws_iam_role.controltower_stackset.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::*:role/AWSControlTowerExecution"
    }]
  })
}

# CloudTrail assumes this role to publish the organization trail's logs.
resource "aws_iam_role" "controltower_cloudtrail" {
  name = "AWSControlTowerCloudTrailRole"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "controltower_cloudtrail" {
  role       = aws_iam_role.controltower_cloudtrail.name
  policy_arn = data.aws_iam_policy.controltower_cloudtrail_role.arn
}

# --- Landing zone ------------------------------------------------------------

# Creating or updating a landing zone can take an hour or more.
#
# The manifest names the two accounts Control Tower builds on, which must
# already exist in the same OU directly under the root (our Security OU):
#   - Log_Archive receives the organization CloudTrail and AWS Config logs.
#   - Audit holds the Config aggregator and Control Tower's security roles.
#
# accessManagement is off because this repository manages IAM Identity Center
# itself (see staged/service_identitycenter.tf). backup is off: AWS Backup
# integration needs two further accounts and is left for teams that want it.
resource "aws_controltower_landing_zone" "this" {
  version = local.controltower_landing_zone_version

  manifest_json = jsonencode({
    accessManagement = {
      enabled = false
    }
    backup = {
      enabled = false
    }
    centralizedLogging = {
      enabled   = true
      accountId = module.acct_log_archive.account_id
      configurations = {
        loggingBucket       = { retentionDays = var.log_retention_days }
        accessLoggingBucket = { retentionDays = 365 }
      }
    }
    config = {
      enabled   = true
      accountId = module.acct_audit.account_id
      configurations = {
        loggingBucket       = { retentionDays = var.log_retention_days }
        accessLoggingBucket = { retentionDays = 365 }
      }
    }
    # Control Tower governs only these regions. Each must be a region where
    # Control Tower is available.
    governedRegions = sort(var.allowed_regions)
    securityRoles = {
      enabled   = true
      accountId = module.acct_audit.account_id
    }
  })

  lifecycle {
    # Decommissioning a landing zone is slow and hard to undo.
    prevent_destroy = true
  }

  depends_on = [
    aws_iam_role_policy.controltower_admin,
    aws_iam_role_policy_attachment.controltower_admin,
    aws_iam_role_policy.controltower_stackset,
    aws_iam_role_policy_attachment.controltower_cloudtrail,
    aws_account_region.management,
  ]
}

# --- OU registration ---------------------------------------------------------

# Registering an OU applies the Control Tower baseline to every account in
# it, and is required before Account Factory can place an account there.
resource "aws_controltower_baseline" "ou" {
  for_each = local.controltower_registered_ous

  baseline_identifier = local.controltower_ou_baseline_arn
  baseline_version    = local.controltower_ou_baseline_version
  target_identifier   = each.value.arn

  depends_on = [aws_controltower_landing_zone.this]
}
