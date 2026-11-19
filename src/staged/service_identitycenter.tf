# -----------------------------------------------------------------------------
# IAM Identity Center
#
# Terraform manages all Groups and Permission Sets. We also manage superadmin
# users via the service_identitycenter_users.tf file. All other users are
# managed via the console.
#
# Administration is delegated to the Shared Services account (per AWS SRA),
# so day-to-day console user/group management happens there rather than in
# the Management Account.
#
# Staged: this folder is not loaded by the root module. Terraform cannot
# enable Identity Center for an organization, and everything here needs the
# instance to exist. Enable it in the console first, in your home region,
# then move this file and service_identitycenter_users.tf to /src.
# -----------------------------------------------------------------------------

data "aws_ssoadmin_instances" "this" {}

locals {
  # The lookup returns an empty list until Identity Center is enabled.
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

output "identity_center_instance_arn" {
  description = "ARN of the IAM Identity Center instance."
  value       = local.sso_instance_arn
}

# --- Delegated Administration --------------------------------------------------

# The Shared Services account is the delegated admin for Identity Center. It
# can manage users, groups, and member-account permission sets and
# assignments, but not permission sets provisioned in the Management
# Account. OrgAdmins is one (via the superadmin assignments in
# service_identitycenter_users.tf), so it is manageable only from the
# Management Account. A dedicated management-account permission set would
# lift that restriction; deliberately not done for now.
resource "aws_organizations_delegated_administrator" "identity_center" {
  account_id        = module.acct_shared_services.account_id
  service_principal = "sso.amazonaws.com"

  depends_on = [aws_organizations_organization.this]
}

# --- Groups ------------------------------------------------------------------

# OrgAdmins Group
resource "aws_identitystore_group" "org_admins" {
  identity_store_id = local.identity_store_id
  display_name      = "OrgAdmins"
  description       = "Organization administrators: full access to all accounts, managed in Terraform."
}

# OrgReadOnly Group
resource "aws_identitystore_group" "org_readonly" {
  identity_store_id = local.identity_store_id
  display_name      = "OrgReadOnly"
  description       = "Read-only access to our entire organization"
}

# WorkloadDevelopers Group
resource "aws_identitystore_group" "workload_devs" {
  identity_store_id = local.identity_store_id
  display_name      = "WorkloadDevelopers"
  description       = "WorkloadDevelopers group. Access to the workload accounts."
}

# --- Permission Sets ---------------------------------------------------------

# OrgAdmins Permission Set
resource "aws_ssoadmin_permission_set" "org_admin" {
  instance_arn = local.sso_instance_arn
  name         = local.sso_admin_permission_set_name
  description  = "Full administrator access, for organization administrators only."
  # TODO: consider reducing this. It is the session duration of superadmins
  # with *write* access to the entire organization.
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "org_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# OrgReadOnly Permission Set
resource "aws_ssoadmin_permission_set" "org_readonly" {
  instance_arn     = local.sso_instance_arn
  name             = "OrgReadOnly"
  description      = "Read-only access to our entire organization"
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "org_readonly1" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "org_readonly2" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
}

# WorkloadDevelopers Permission Sets
resource "aws_ssoadmin_permission_set" "workload_devs" {
  instance_arn     = local.sso_instance_arn
  name             = "WorkloadDevelopers"
  description      = "WorkloadDevelopers full administrator access."
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "workload_devs_policy1" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_devs.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Account Assignments: OrgAdmins Group ------------------------------------

resource "aws_ssoadmin_account_assignment" "org_admin_log_archive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_log_archive.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_admin_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_audit.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_admin_shared_services" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_shared_services.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_admin_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_sandbox.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_admin_dev" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_dev.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_admin_prod" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_group.org_admins.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_prod.account_id
  target_type        = "AWS_ACCOUNT"
}

# --- Account Assignments: OrgReadOnly Group ------------------------------------

resource "aws_ssoadmin_account_assignment" "org_readonly_log_archive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_group.org_readonly.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_log_archive.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_group.org_readonly.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_audit.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_shared_services" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_group.org_readonly.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_shared_services.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_group.org_readonly.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_sandbox.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_dev" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_group.org_readonly.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_dev.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_prod" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_group.org_readonly.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_prod.account_id
  target_type        = "AWS_ACCOUNT"
}

# --- Account Assignments: WorkloadDevelopers Group ---------------------------

resource "aws_ssoadmin_account_assignment" "workload_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_devs.arn
  principal_id       = aws_identitystore_group.workload_devs.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_sandbox.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "workload_dev" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_devs.arn
  principal_id       = aws_identitystore_group.workload_devs.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_dev.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "workload_prod" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_devs.arn
  principal_id       = aws_identitystore_group.workload_devs.group_id
  principal_type     = "GROUP"
  target_id          = module.acct_workload_prod.account_id
  target_type        = "AWS_ACCOUNT"
}
