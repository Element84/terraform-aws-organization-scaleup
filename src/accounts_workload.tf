# -----------------------------------------------------------------------------
# Workload Accounts
#
# An example workload: dev and prod in the Workloads OU, a sandbox in the
# Sandbox OU. Repeat this pattern for each project or team.
#
# Each account is created through Control Tower Account Factory, which
# provisions at most five accounts at a time. When adding several at once,
# chain them with depends_on.
# -----------------------------------------------------------------------------

module "acct_workload_dev" {
  source = "./modules/account_factory"

  name    = "Workload_Dev"
  email   = "${var.base_email.user}+workload-dev-acct@${var.base_email.domain}"
  ou_name = aws_organizations_organizational_unit.workloads.name
  ou_id   = aws_organizations_organizational_unit.workloads.id

  # These should almost always be the same for every account. They are
  # inputs only to allow for variance later.
  contacts       = var.contacts
  opt_in_regions = local.opt_in_regions

  # depends_on is required on every call to this module. The contact and
  # region resources use the Account Management API, which needs trusted
  # access, and Account Factory needs the target OU registered.
  depends_on = [
    aws_organizations_aws_service_access.account_management,
    aws_controltower_baseline.ou,
  ]
}

module "acct_workload_prod" {
  source = "./modules/account_factory"

  name           = "Workload_Prod"
  email          = "${var.base_email.user}+workload-prod-acct@${var.base_email.domain}"
  ou_name        = aws_organizations_organizational_unit.workloads.name
  ou_id          = aws_organizations_organizational_unit.workloads.id
  contacts       = var.contacts
  opt_in_regions = local.opt_in_regions

  depends_on = [
    aws_organizations_aws_service_access.account_management,
    aws_controltower_baseline.ou,
  ]
}

module "acct_workload_sandbox" {
  source = "./modules/account_factory"

  name           = "Workload_Sandbox"
  email          = "${var.base_email.user}+workload-sandbox-acct@${var.base_email.domain}"
  ou_name        = aws_organizations_organizational_unit.sandbox.name
  ou_id          = aws_organizations_organizational_unit.sandbox.id
  contacts       = var.contacts
  opt_in_regions = local.opt_in_regions

  depends_on = [
    aws_organizations_aws_service_access.account_management,
    aws_controltower_baseline.ou,
  ]
}
