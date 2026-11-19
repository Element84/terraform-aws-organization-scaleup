# -----------------------------------------------------------------------------
# Account Factory Module
#
# Provisions one member account through AWS Control Tower Account Factory, so
# it arrives enrolled in the landing zone with logging and controls in place.
#
# Account Factory is a Service Catalog product. The principal running
# Terraform must have access to the "AWS Control Tower Account Factory
# Portfolio" (see docs/0_setup.md), and the target OU must be registered with
# Control Tower. Control Tower provisions at most five accounts at a time.
#
# Every call to this module must set:
#   depends_on = [
#     aws_organizations_aws_service_access.account_management,
#     aws_controltower_baseline.ou,
#   ]
# -----------------------------------------------------------------------------

resource "aws_servicecatalog_provisioned_product" "this" {
  name                       = var.name
  product_name               = "AWS Control Tower Account Factory"
  provisioning_artifact_name = "AWS Control Tower Account Factory"

  provisioning_parameters {
    key   = "AccountName"
    value = var.name
  }

  provisioning_parameters {
    key   = "AccountEmail"
    value = var.email
  }

  # Account Factory expects the OU as "Name (ou-id)".
  provisioning_parameters {
    key   = "ManagedOrganizationalUnit"
    value = "${var.ou_name} (${var.ou_id})"
  }

  # Required by the product but unused: this landing zone manages IAM
  # Identity Center itself (accessManagement is disabled), so Control Tower
  # creates no user from these values.
  provisioning_parameters {
    key   = "SSOUserEmail"
    value = var.email
  }

  provisioning_parameters {
    key   = "SSOUserFirstName"
    value = "Unused"
  }

  provisioning_parameters {
    key   = "SSOUserLastName"
    value = "Unused"
  }

  timeouts {
    create = "60m"
    update = "60m"
  }

  lifecycle {
    # Accounts are rarely, if ever, deleted. To remove one, delete this line
    # first: Terraform does not allow prevent_destroy to be set from a
    # variable.
    prevent_destroy = true
  }
}

locals {
  # Account Factory reports the new account's ID as a product output.
  account_id = one([
    for o in aws_servicecatalog_provisioned_product.this.outputs : o.value
    if o.key == "AccountId"
  ])

  # Alternate contacts keyed by the AWS contact type.
  alternate_contacts = {
    BILLING    = var.contacts.billing
    OPERATIONS = var.contacts.operations
    SECURITY   = var.contacts.security
  }
}

# --- Contacts ----------------------------------------------------------------

resource "aws_account_primary_contact" "this" {
  account_id         = local.account_id
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

resource "aws_account_alternate_contact" "this" {
  for_each = local.alternate_contacts

  account_id             = local.account_id
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

  account_id  = local.account_id
  region_name = each.value
  enabled     = true
}
