data "aws_caller_identity" "current" {}

locals {
  # Root of the organization. Used by OUs and other core resources.
  org_root_id = aws_organizations_organization.this.roots[0].id

  # Cross-account role created in every member account by Organizations.
  org_access_role = "OrganizationAccountAccessRole"

  # Aggregated Security Hub findings are stored in this region. It must be
  # a default-enabled region. A precondition in service_securityhub.tf
  # enforces that requirement.
  securityhub_aggregation_region = coalesce(var.securityhub_aggregation_region, var.home_region)

  # Name of the Identity Center org-admin permission set (see
  # staged/service_identitycenter.tf). Its roles are named
  # AWSReservedSSO_<name>_*, which is the pattern to exempt when a Control
  # Tower control accepts exempted principals.
  #
  # Deliberately not the generic "AdministratorAccess": permission set names
  # are unique per Identity Center instance, so a distinctive name stops the
  # console side (which manages every other permission set) from reusing it
  # and blurring the Terraform/console boundary.
  # Do not change after deployment: doing so replaces the permission set and
  # re-provisions every account's AWSReservedSSO_<name>_* roles.
  sso_admin_permission_set_name = "OrgAdministrator"
}
