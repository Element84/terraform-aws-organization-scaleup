# -----------------------------------------------------------------------------
# Root Management Account
#
# The management account is special: it pre-exists the organization, lives
# outside any OU, and is not managed as an account resource. Resources here
# omit account_id, which makes them target the current (management) account.
# -----------------------------------------------------------------------------

locals {
  # Alternate contacts for the management account, keyed by the AWS contact
  # type.
  mgmt_alternate_contacts = {
    BILLING    = var.contacts.billing
    OPERATIONS = var.contacts.operations
    SECURITY   = var.contacts.security
  }
}

resource "aws_account_primary_contact" "management" {
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

resource "aws_account_alternate_contact" "management" {
  for_each = local.mgmt_alternate_contacts

  alternate_contact_type = each.key
  name                   = each.value.name
  title                  = each.value.title
  email_address          = each.value.email_address
  phone_number           = each.value.phone_number
}

# --- Opt-in regions ------------------------------------------------------------

resource "aws_account_region" "management" {
  for_each = local.opt_in_regions

  region_name = each.value
  enabled     = true
}
