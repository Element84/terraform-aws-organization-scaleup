# -----------------------------------------------------------------------------
# GuardDuty
#
# Delegated to the Audit account, enabled in every covered region
# (local.security_regions = all default-enabled regions + allowed_regions).
#
# GuardDuty is regional: the delegated-admin designation, the detector, and
# the org auto-enable setting all exist per region. Coverage everywhere
# protects against activity in regions we don't use - most importantly by
# the management account, which no guardrail restricts. Idle-region detectors cost
# almost nothing (billing is by analyzed event volume).
#
# Multi-region is handled with the provider v6 per-resource `region`
# argument - no per-region provider aliases needed.
# -----------------------------------------------------------------------------

# Designating a delegated admin enables guardduty.amazonaws.com trusted
# access, which is why GuardDuty is absent from service_organizations.tf.
resource "aws_guardduty_organization_admin_account" "this" {
  for_each = local.security_regions

  region           = each.value
  admin_account_id = module.acct_audit.account_id

  depends_on = [
    aws_organizations_organization.this,
    aws_account_region.management,
  ]
}

# Unlike console designation, the API designation above does not enable the
# separate Malware Protection principal, which lets the delegated admin
# create that feature's service-linked role in member accounts. This grants
# permission only; enabling the protection plan is a separate decision.
# Explicit here because the org resource ignores aws_service_access_principals.
resource "aws_organizations_aws_service_access" "guardduty_malware_protection" {
  service_principal = "malware-protection.guardduty.amazonaws.com"

  depends_on = [aws_organizations_organization.this]
}

# The account modules contain the member-account opt-in region enablement,
# so depending on them guarantees every region exists before detectors
# cover it.
resource "aws_guardduty_detector" "audit" {
  provider = aws.audit
  for_each = local.security_regions

  region                       = each.value
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"

  depends_on = [
    aws_guardduty_organization_admin_account.this,
    module.acct_log_archive,
    module.acct_audit,
    module.acct_shared_services,
    module.acct_workload_dev,
    module.acct_workload_prod,
    module.acct_workload_sandbox,
  ]
}

resource "aws_guardduty_organization_configuration" "this" {
  provider = aws.audit
  for_each = local.security_regions

  region                           = each.value
  detector_id                      = aws_guardduty_detector.audit[each.key].id
  auto_enable_organization_members = "ALL"
}

# --- Management Account  ------------------------------------------------------
#
# auto_enable_organization_members = "ALL" covers member accounts only. AWS
# requires the management account to enable GuardDuty itself before the
# delegated admin can add it as a member. Without this, the account most
# exposed to credential abuse (no guardrail restricts it) would have no detector.

resource "aws_guardduty_detector" "management" {
  for_each = local.security_regions

  region                       = each.value
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"

  # Opt-in regions must be enabled in the management account first.
  depends_on = [aws_account_region.management]
}

# Associates the management account as a member from the Audit account. Both
# are in the organization, so this is a direct association with no
# invitation (invite defaults to false).
resource "aws_guardduty_member" "management" {
  provider = aws.audit
  for_each = local.security_regions

  region      = each.value
  detector_id = aws_guardduty_detector.audit[each.key].id
  account_id  = aws_organizations_organization.this.master_account_id
  email       = aws_organizations_organization.this.master_account_email

  # GetMembers never returns the email of an org-associated member, and the
  # provider infers `invite` from the relationship status, so both attributes
  # drift on every refresh - email's ForceNew would plan a needless
  # disassociate/re-associate each time. See provider issue #13906.
  lifecycle {
    ignore_changes = [email, invite]
  }

  depends_on = [aws_guardduty_detector.management]
}
