# -----------------------------------------------------------------------------
# Security Hub
#
# The single console, in the Audit account, where the security team sees
# every finding from every account and region.
#
# Findings aggregation only: no security standards are enabled, so there is
# no per-check billing and no AWS Config prerequisite. GuardDuty publishes
# findings into Security Hub wherever both are enabled, and the finding
# aggregator pulls every region into the aggregation region.
#
# Unlike GuardDuty's per-region fan-out, Security Hub uses central
# configuration: one policy associated with the org root enables the service
# in every current and future account, management account included, across
# the aggregation region and all linked regions.
# -----------------------------------------------------------------------------

# Designating a delegated admin enables securityhub.amazonaws.com trusted
# access (same pattern as GuardDuty) and enables Security Hub in the Audit
# account, in the region of the call. It targets the aggregation region
# because the finding aggregator below can only be created where Security
# Hub is already enabled in the Audit account.
resource "aws_securityhub_organization_admin_account" "this" {
  region = local.securityhub_aggregation_region

  admin_account_id = module.acct_audit.account_id

  depends_on = [
    aws_organizations_organization.this,
    aws_account_region.management,
    module.acct_audit,
  ]
}

# Cross-region aggregation into the aggregation region: the "single pane",
# and a prerequisite for central configuration. ALL_REGIONS matches
# GuardDuty's all-region coverage and picks up future regions automatically.
resource "aws_securityhub_finding_aggregator" "this" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  linking_mode = "ALL_REGIONS"

  lifecycle {
    precondition {
      condition     = contains(local.default_regions, local.securityhub_aggregation_region)
      error_message = "The Security Hub aggregation region (${local.securityhub_aggregation_region}) must be a default-enabled region. Set securityhub_aggregation_region to one; home_region can stay an opt-in region."
    }
  }

  depends_on = [aws_securityhub_organization_admin_account.this]
}

# Switches to central configuration. auto_enable = false and
# auto_enable_standards = "NONE" are required alongside CENTRAL: those flags
# belong to the local per-region model. The root policy association below
# covers new accounts instead.
resource "aws_securityhub_organization_configuration" "this" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  auto_enable           = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }

  depends_on = [aws_securityhub_finding_aggregator.this]
}

# Security Hub on, standards deliberately empty: findings aggregation only.
# Enabling best-practice checks later (e.g. FSBP) is a one-line change here,
# but requires AWS Config recording org-wide first and starts per-check
# billing.
resource "aws_securityhub_configuration_policy" "baseline" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  name        = "${var.rsc_name}-baseline"
  description = "Security Hub enabled in every account with no standards - findings aggregation only."

  configuration_policy {
    service_enabled       = true
    enabled_standard_arns = []

    # Required whenever service_enabled is true, even with no standards
    # enabled. Disabling zero controls keeps this a pure
    # findings-aggregation policy.
    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }

  depends_on = [aws_securityhub_organization_configuration.this]
}

# Root association: applies the policy to every current and future account.
resource "aws_securityhub_configuration_policy_association" "root" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  target_id = local.org_root_id
  policy_id = aws_securityhub_configuration_policy.baseline.id
}
