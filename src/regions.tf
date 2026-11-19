# -----------------------------------------------------------------------------
# AWS Regions
#
# Opt-in regions (e.g. af-south-1) are disabled in every account until
# explicitly enabled, per account. Any opt-in region listed in
# var.allowed_regions is enabled in two places:
#   - member accounts:   inside modules/account and modules/account_factory
#                        (opt_in_regions input)
#   - management account: accounts_mgmt.tf
#
# Default-enabled regions are discovered dynamically rather than hardcoded.
# -----------------------------------------------------------------------------

data "aws_regions" "default_enabled" {
  all_regions = true

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  default_regions = data.aws_regions.default_enabled.names

  # Opt-in regions requested via allowed_regions. Empty when every allowed
  # region is enabled by default.
  opt_in_regions = setsubtract(toset(var.allowed_regions), local.default_regions)

  # Region set for the security services (GuardDuty, Access Analyzer): every
  # default-enabled region plus every allowed region.
  security_regions = setunion(local.default_regions, toset(var.allowed_regions))
}
