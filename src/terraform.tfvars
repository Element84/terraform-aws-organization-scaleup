# -----------------------------------------------------------------------------
# Non-Secret Settings
#
# Core settings used throughout the project. See variables.tf for detail.
# These values are not sensitive, so they can be committed. Set any sensitive
# variable through a TF_VAR_ environment variable instead.
# -----------------------------------------------------------------------------

# TODO: every value in this file is a placeholder. Replace each one with your
# own before applying.

monthly_budget_usd = 1000

# IMPORTANT: keep this list up to date. See variables.tf for detail.
# If the people to notify of security incidents change, also update the AWS
# Incident Response contacts by hand in the AWS console.
security_notifications = [
  "security@example.com",
  "aws+securityincident@example.com",
  "jane.doe@example.com",
]

# IMPORTANT: keep this list up to date. See variables.tf for detail.
cost_notifications = [
  "procurement@example.com",
  "aws+costalert@example.com",
  "adam.doe@example.com",
  "jessie.roe@example.com"
]

contacts = {
  primary = {
    full_name       = "IT Manager"
    company_name    = "Example Corp"
    address_line_1  = "123 Example Street"
    city            = "Seattle"
    state_or_region = "WA"
    postal_code     = "98101"
    country_code    = "US"
    website_url     = "https://www.example.com"
    phone_number    = "+15555550100"
  }
  billing = {
    name          = "Jennifer Poe"
    title         = "Procurement Shared Inbox"
    email_address = "procurement@example.com"
    phone_number  = "+15555550101"
  }
  operations = {
    name          = "Fred Clark"
    title         = "Cloud Ops Shared Inbox"
    email_address = "ops@example.com"
    phone_number  = "+15555550102"
  }
  security = {
    name          = "Jane Doe"
    title         = "Security Shared Inbox"
    email_address = "jane.doe@example.com"
    phone_number  = "+15555550103"
  }
}

# TODO: the warning below is only applicable after you've set up your initial
# AWS environment.
# -----------------------------------------------------------------------------
# WARNING: TAKE EXTREME CARE
#
# Changing any value below may cause major changes to the AWS environment.
# allowed_regions is the one you may want to add to later. Do not remove a
# region that is in use, or you may break existing functionality. Leave the
# others unchanged unless you are certain.
# -----------------------------------------------------------------------------

allowed_regions = ["us-west-2"]
home_region     = "us-west-2"
rsc_name        = "org-core"

# If your home_region set above is an opt-in AWS region, you'll need
# to set this to a default-enabled region. See variables.tf for details.
# securityhub_aggregation_region = "us-west-2"

# Changing this would replace (destroy and recreate) every AWS account. A
# lifecycle rule in the account module blocks that. To change account email
# addresses instead:
# 1. In the Management Account console, open AWS Organizations and update
#    each account's primary email address.
# 2. Update the values below to match.
# 3. Run a terraform apply. It will report the change made outside of
#    Terraform in step 1.
base_email = {
  user   = "aws"
  domain = "example.com"
}
