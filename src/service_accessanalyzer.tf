# -----------------------------------------------------------------------------
# IAM Access Analyzer
#
# External access analysis, delegated to the Audit account and enabled in
# every covered region. Analysis is continuous and free. The paid
# unused-access and internal-access analyzers are deliberately not enabled.
#
# Findings flow into Security Hub and aggregate into the aggregation region
# alongside GuardDuty.
#
# The management account also gets an ACCOUNT analyzer in every covered
# region, for two reasons. The organization analyzers do not satisfy Trusted
# Advisor's account-level external-access check. And their zone of trust is
# the whole organization, so they trust a management-account resource shared
# with a member account; the account is the right zone of trust for the one
# account no guardrail restricts. Member accounts stay on the organization
# analyzers only: an account analyzer there would flag ordinary intra-org
# sharing.
#
# A management-account resource shared outside the organization is reported
# twice, once by each analyzer. Intra-org sharing of management-account
# resources appears only on the account analyzer.
# -----------------------------------------------------------------------------

# Unlike GuardDuty and Security Hub, designating a delegated admin for
# Access Analyzer does not enable trusted access, so both steps are explicit
# here. Same pattern as account.amazonaws.com in service_organizations.tf.
resource "aws_organizations_aws_service_access" "access_analyzer" {
  service_principal = "access-analyzer.amazonaws.com"

  depends_on = [aws_organizations_organization.this]
}

# Registration is org-wide: one delegated admin covers all regions.
resource "aws_organizations_delegated_administrator" "access_analyzer" {
  account_id        = module.acct_audit.account_id
  service_principal = "access-analyzer.amazonaws.com"

  depends_on = [aws_organizations_aws_service_access.access_analyzer]
}

# Organization analyzers created from the delegated admin require this
# service-linked role to already exist in the management account.
resource "aws_iam_service_linked_role" "access_analyzer" {
  aws_service_name = "access-analyzer.amazonaws.com"
}

# Member accounts need no resources of their own: the org analyzer reaches
# into them through a service-linked role AWS creates automatically.
resource "aws_accessanalyzer_analyzer" "external" {
  provider = aws.audit
  for_each = local.security_regions

  region        = each.value
  analyzer_name = "${var.rsc_name}-org-external-access"
  type          = "ORGANIZATION"

  depends_on = [
    aws_organizations_delegated_administrator.access_analyzer,
    aws_iam_service_linked_role.access_analyzer,
    module.acct_audit,
  ]
}

# IAM roles are global, so every regional analyzer re-reports them (~18
# copies of each finding). Auto-archive AWS::IAM::Role findings everywhere
# except the home region, so each real IAM issue stays active exactly once,
# there and in Security Hub.
#
# Archive rules only act on findings created after the rule exists, and
# analyzers start scanning immediately, so the first apply may leave a
# one-time burst of IAM duplicates in non-home regions. Bulk-archive those in
# the console, or ignore them.
resource "aws_accessanalyzer_archive_rule" "iam_dedupe" {
  provider = aws.audit
  for_each = setsubtract(local.security_regions, [var.home_region])

  region        = each.value
  analyzer_name = aws_accessanalyzer_analyzer.external[each.key].analyzer_name
  rule_name     = "${var.rsc_name}-archive-global-iam-role-findings"

  filter {
    criteria = "resourceType"
    eq       = ["AWS::IAM::Role"]
  }
}

# --- Management account -------------------------------------------------------
#
# Trusted Advisor looks for an analyzer in the account itself; the org
# analyzers above live in Audit and are not counted. Same shape as the
# GuardDuty management detectors: delegated admin does not cover this check
# for the management account.
#
# Zone of trust is the account, so a resource policy granting a member
# account access to a management-account resource is a finding. Archive that
# finding if the sharing is intentional. Do not switch this analyzer to
# ORGANIZATION to hide it: only one organization external-access analyzer is
# allowed per region, and Audit already holds it.

resource "aws_accessanalyzer_analyzer" "management" {
  for_each = local.security_regions

  region        = each.value
  analyzer_name = "${var.rsc_name}-mgmt-external-access"
  type          = "ACCOUNT"

  # Opt-in regions must be enabled in the management account first. The
  # service-linked role already exists here because the org analyzers
  # require it in the management account.
  depends_on = [
    aws_iam_service_linked_role.access_analyzer,
    aws_account_region.management,
  ]
}

# Same dedupe as the org analyzers: auto-archive AWS::IAM::Role findings
# everywhere except the home region, which keeps the one live copy. The same
# first-apply caveat applies.
resource "aws_accessanalyzer_archive_rule" "management_iam_dedupe" {
  for_each = setsubtract(local.security_regions, [var.home_region])

  region        = each.value
  analyzer_name = aws_accessanalyzer_analyzer.management[each.key].analyzer_name
  rule_name     = "${var.rsc_name}-archive-global-iam-role-findings"

  filter {
    criteria = "resourceType"
    eq       = ["AWS::IAM::Role"]
  }
}
