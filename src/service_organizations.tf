# -----------------------------------------------------------------------------
# AWS Organizations
#
# The core of the landing zone: organizational units separate concerns,
# member accounts are managed consistently, and guardrails apply across the
# organization.
# -----------------------------------------------------------------------------

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  # Trusted access: per AWS's recommendation, services enable trusted access
  # for themselves via their own APIs, so aws_service_access_principals is
  # deliberately not set here. Services with no self-enablement path (e.g.
  # account.amazonaws.com) are enabled individually below.
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "RESOURCE_CONTROL_POLICY",
    "DECLARATIVE_POLICY_EC2",
    "S3_POLICY",
    "AISERVICES_OPT_OUT_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
    "SECURITYHUB_POLICY",
    "INSPECTOR_POLICY",
    "CHATBOT_POLICY",
  ]

  lifecycle {
    # An AWS Org cannot be deleted until all member accounts are removed,
    # but an accidental destroy attempt can still cause major issues.
    prevent_destroy = true

    # Guards against the provider treating the omitted principals list as
    # "manage to empty" and disabling self-enabled services.
    ignore_changes = [aws_service_access_principals]
  }
}

# Account Management cannot self-enable trusted access; Organizations-side
# enablement is the documented method. Required for managing contacts on
# member accounts (see modules/account and modules/account_factory).
resource "aws_organizations_aws_service_access" "account_management" {
  service_principal = "account.amazonaws.com"

  depends_on = [aws_organizations_organization.this]
}

# IAM trusted access is likewise a documented prerequisite for centralized
# root access management - the IAM feature APIs do not enable it themselves.
resource "aws_organizations_aws_service_access" "iam" {
  service_principal = "iam.amazonaws.com"

  depends_on = [aws_organizations_organization.this]
}

# Trusted access for Inspector
resource "aws_organizations_aws_service_access" "inspector2" {
  service_principal = "inspector2.amazonaws.com"

  depends_on = [aws_organizations_organization.this]
}

# --- Organizational Units ----------------------------------------------------

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.org_root_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = local.org_root_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.org_root_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = local.org_root_id

  lifecycle {
    prevent_destroy = true
  }
}

# --- Root Hardening: Centralized Root Access Management ---------------------
#
# Lets the management account own the root credentials of member accounts,
# so MFA enrollment / access-key cleanup never happens by hand per account:
#   - RootCredentialsManagement: centrally manage and remove member root creds
#   - RootSessions:              perform the rare root-only tasks centrally
#
# Does *not* apply to the management account's own root, which is hardened
# manually (MFA on, no access keys). Accounts vended through Organizations
# carry no standing root credentials to begin with.

resource "aws_iam_organizations_features" "root_access_management" {
  enabled_features = [
    "RootCredentialsManagement",
    "RootSessions",
  ]

  # Trusted access for iam.amazonaws.com is a prerequisite.
  depends_on = [aws_organizations_aws_service_access.iam]
}
