# -----------------------------------------------------------------------------
# Account Creation Module
#
# Provisions one member account following our org best practices.
#
# Every call to this module must set:
#   depends_on = [aws_organizations_aws_service_access.account_management]
# -----------------------------------------------------------------------------

resource "aws_organizations_account" "this" {
  name      = var.name
  email     = var.email
  parent_id = var.parent_id
  role_name = var.role_name

  # Org-wide policy, deliberately not configurable per account.
  iam_user_access_to_billing = "ALLOW"
  close_on_deletion          = false

  lifecycle {
    # Accounts are rarely, if ever, deleted. To remove one, delete this line
    # first: Terraform does not allow prevent_destroy to be set from a
    # variable.
    prevent_destroy = true

    # These can only be set at creation time; ignore to avoid forced
    # replacement of the account on future changes.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}

# --- Contacts ----------------------------------------------------------------

resource "aws_account_primary_contact" "this" {
  account_id         = aws_organizations_account.this.id
  full_name          = var.contacts.primary.full_name
  company_name       = var.contacts.primary.company_name
  address_line_1     = var.contacts.primary.address_line_1
  address_line_2     = var.contacts.primary.address_line_2
  city               = var.contacts.primary.city
  state_or_region    = var.contacts.primary.state_or_region
  postal_code        = var.contacts.primary.postal_code
  country_code       = var.contacts.primary.country_code
  phone_number       = var.contacts.primary.phone_number
  website_url        = var.contacts.primary.website_url
  district_or_county = var.contacts.primary.district_or_county
}

locals {
  # Alternate contacts keyed by the AWS contact type.
  alternate_contacts = {
    BILLING    = var.contacts.billing
    OPERATIONS = var.contacts.operations
    SECURITY   = var.contacts.security
  }
}

resource "aws_account_alternate_contact" "this" {
  for_each = local.alternate_contacts

  account_id             = aws_organizations_account.this.id
  alternate_contact_type = each.key
  name                   = each.value.name
  title                  = each.value.title
  email_address          = each.value.email_address
  phone_number           = each.value.phone_number
}

# --- Opt-in Regions ------------------------------------------------------------

# Enablement is asynchronous on the AWS side and can take several minutes per
# region. Removing a region from the input disables it in the account again on
# the next apply.
resource "aws_account_region" "this" {
  for_each = toset(var.opt_in_regions)

  account_id  = aws_organizations_account.this.id
  region_name = each.value
  enabled     = true
}
