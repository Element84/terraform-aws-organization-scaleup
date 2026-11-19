# -----------------------------------------------------------------------------
# IAM Identity Center: Organization Superadmin Users Only
#
# This file holds the organization superadmins and nothing else. Every other
# user is created in the console by an org admin and is deliberately absent
# from this repo. See the ownership notes in service_identitycenter.tf.
# -----------------------------------------------------------------------------

# TODO: Jane Doe and John Roe are placeholders. Replace them with your own
# superadmins before applying, or these users will be created for real.

# Superadmin: Jane Doe
resource "aws_identitystore_user" "jdoe" {
  identity_store_id = local.identity_store_id

  display_name = "Jane Doe"
  name {
    given_name  = "Jane"
    family_name = "Doe"
  }

  # user_name is what the user logs in with. Using their email address avoids
  # "what is my username?" confusion.
  user_name = "jane.doe@example.com"
  emails {
    value   = "jane.doe@example.com"
    primary = true
  }
}

# Add the admin to the OrgAdmins group: admin access to every account
# *except* the Management Account.
resource "aws_identitystore_group_membership" "jdoe_group1" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.org_admins.group_id
  member_id         = aws_identitystore_user.jdoe.user_id
}

# Add the admin to the OrgReadOnly group.
resource "aws_identitystore_group_membership" "jdoe_group2" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.org_readonly.group_id
  member_id         = aws_identitystore_user.jdoe.user_id
}

# Grant access to the Management Account directly, not via a group. See the
# note at the bottom of this file for why.
resource "aws_ssoadmin_account_assignment" "org_admin_management_jdoe" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_user.jdoe.user_id
  principal_type     = "USER"
  target_id          = data.aws_caller_identity.current.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_management_jdoe2" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_user.jdoe.user_id
  principal_type     = "USER"
  target_id          = data.aws_caller_identity.current.account_id
  target_type        = "AWS_ACCOUNT"
}

# Superadmin: John Roe
resource "aws_identitystore_user" "jroe" {
  identity_store_id = local.identity_store_id

  display_name = "John Roe"
  name {
    given_name  = "John"
    family_name = "Roe"
  }

  # user_name is what the user logs in with. Using their email address avoids
  # "what is my username?" confusion.
  user_name = "john.roe@example.com"
  emails {
    value   = "john.roe@example.com"
    primary = true
  }
}

# Add the admin to the OrgAdmins group: admin access to every account
# *except* the Management Account.
resource "aws_identitystore_group_membership" "jroe_group1" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.org_admins.group_id
  member_id         = aws_identitystore_user.jroe.user_id
}

# Add the admin to the OrgReadOnly group.
resource "aws_identitystore_group_membership" "jroe_group2" {
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.org_readonly.group_id
  member_id         = aws_identitystore_user.jroe.user_id
}

# Grant access to the Management Account directly, not via a group. See the
# note at the bottom of this file for why.
resource "aws_ssoadmin_account_assignment" "org_admin_management_jroe" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_admin.arn
  principal_id       = aws_identitystore_user.jroe.user_id
  principal_type     = "USER"
  target_id          = data.aws_caller_identity.current.account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "org_readonly_management_jroe2" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.org_readonly.arn
  principal_id       = aws_identitystore_user.jroe.user_id
  principal_type     = "USER"
  target_id          = data.aws_caller_identity.current.account_id
  target_type        = "AWS_ACCOUNT"
}


# NOTE: Granting Admin Access to the Management Account
#
# Management-account admin is granted per user, not via the OrgAdmins group.
# A group membership added in the console is a resource Terraform cannot see,
# so a group-based assignment would let a console-side group edit silently
# confer management-account admin. Per-user, a console-added OrgAdmins
# member gets member-account admin (visible, recoverable) but never the
# management account.
#
# It also keeps delegation safe. A delegated Identity Center admin cannot
# create or modify assignments targeting the management account, but can add
# themselves to a group. So the service only protects the management account
# while these assignments stay on users. Do NOT fold them into a group
# assignment.
