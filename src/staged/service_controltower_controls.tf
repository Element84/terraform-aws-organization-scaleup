# -----------------------------------------------------------------------------
# AWS Control Tower Controls
#
# Controls are Control Tower's guardrails. This repository writes no SCPs,
# RCPs, or declarative policies of its own: Control Tower creates and
# attaches them when a control is enabled. The landing zone applies its
# mandatory controls automatically; the optional controls below are enabled
# per OU.
#
# Staged: this folder is not loaded by the root module, so nothing here is
# applied. To apply a control, work through its "Before promoting" note, then
# move it to /src/service_controltower.tf.
#
# Controls apply to registered OUs. They never apply to the management
# account.
# -----------------------------------------------------------------------------

locals {
  # Controls with an AWS-GR_ name have a regional identifier, built here.
  controltower_legacy_control_prefix = "arn:aws:controltower:${var.home_region}::control"

  # Newer controls (named CT.<SERVICE>...) have a global identifier of the
  # form arn:aws:controlcatalog:::control/<id>. AWS does not publish the ids
  # in its documentation.
  # TODO: look up each id you promote, on the control's details page in the
  # Control Tower console or with: aws controlcatalog list-controls
  controltower_global_controls = {
    # Deny access to AWS based on the requested region, for an OU.
    "CT.MULTISERVICE.PV.1" = "arn:aws:controlcatalog:::control/TODO"
    # RCP: STS resources reachable only by the organization's principals.
    "CT.STS.PV.1" = "arn:aws:controlcatalog:::control/TODO"
    # RCP: S3 resources reachable only by the organization's principals.
    "CT.S3.PV.4" = "arn:aws:controlcatalog:::control/TODO"
    # RCP: require encryption in transit for calls to S3.
    "CT.S3.PV.5" = "arn:aws:controlcatalog:::control/TODO"
    # Declarative: disallow public sharing of EBS snapshots.
    "CT.EC2.PV.7" = "arn:aws:controlcatalog:::control/TODO"
    # Declarative: disallow EC2 serial console access.
    "CT.EC2.PV.9" = "arn:aws:controlcatalog:::control/TODO"
    # Declarative: disallow public sharing of AMIs.
    "CT.EC2.PV.11" = "arn:aws:controlcatalog:::control/TODO"
  }
}

# --- Root user ---------------------------------------------------------------

# Disallow actions as the root user.
#
# Before promoting: confirm nobody signs in to a member account as root, and
# that this does not block the centralized root access set up in
# service_organizations.tf. The control accepts exempted principals.
resource "aws_controltower_control" "restrict_root_user" {
  for_each = local.controltower_registered_ous

  control_identifier = "${local.controltower_legacy_control_prefix}/AWS-GR_RESTRICT_ROOT_USER"
  target_identifier  = each.value.arn

  depends_on = [aws_controltower_baseline.ou]
}

# Disallow creating access keys for the root user.
#
# Before promoting: confirm no account still relies on root access keys.
resource "aws_controltower_control" "restrict_root_user_access_keys" {
  for_each = local.controltower_registered_ous

  control_identifier = "${local.controltower_legacy_control_prefix}/AWS-GR_RESTRICT_ROOT_USER_ACCESS_KEYS"
  target_identifier  = each.value.arn

  depends_on = [aws_controltower_baseline.ou]
}

# --- Encryption --------------------------------------------------------------

# Detect EBS volumes attached to EC2 instances that are not encrypted. A
# detective control: it reports, and blocks nothing.
#
# Before promoting: none. Expect findings for existing unencrypted volumes.
resource "aws_controltower_control" "encrypted_volumes" {
  for_each = local.controltower_registered_ous

  control_identifier = "${local.controltower_legacy_control_prefix}/AWS-GR_ENCRYPTED_VOLUMES"
  target_identifier  = each.value.arn

  depends_on = [aws_controltower_baseline.ou]
}

# --- Region deny -------------------------------------------------------------

# Deny work outside allowed_regions. Global services are exempt.
#
# Before promoting: find what already runs in other regions (Cost Explorer
# grouped by region is the quickest check). Anything there keeps running but
# can no longer be managed. Test on the Sandbox OU first. The control also
# accepts ExemptedPrincipalARNs and ExemptedActions.
resource "aws_controltower_control" "region_deny" {
  for_each = local.controltower_registered_ous

  control_identifier = local.controltower_global_controls["CT.MULTISERVICE.PV.1"]
  target_identifier  = each.value.arn

  parameters {
    key   = "AllowedRegions"
    value = jsonencode(sort(var.allowed_regions))
  }

  depends_on = [aws_controltower_baseline.ou]
}

# --- Data perimeter and public sharing ---------------------------------------

# Resource control policies and declarative policies, enabled as controls.
#
# Before promoting: each of these can break a working integration.
#   - CT.STS.PV.1 and CT.S3.PV.4 block access by principals outside the
#     organization, such as a SaaS vendor's role or a partner's account.
#     Inventory that access first.
#   - CT.S3.PV.5 rejects S3 calls that do not use encryption in transit.
#   - CT.EC2.PV.7 and CT.EC2.PV.11 stop public sharing of snapshots and
#     AMIs. CT.EC2.PV.9 removes EC2 serial console access.
resource "aws_controltower_control" "perimeter" {
  for_each = {
    for pair in setproduct(
      ["CT.STS.PV.1", "CT.S3.PV.4", "CT.S3.PV.5", "CT.EC2.PV.7", "CT.EC2.PV.9", "CT.EC2.PV.11"],
      keys(local.controltower_registered_ous),
    ) : "${pair[0]}/${pair[1]}" => { control = pair[0], ou = pair[1] }
  }

  control_identifier = local.controltower_global_controls[each.value.control]
  target_identifier  = local.controltower_registered_ous[each.value.ou].arn

  depends_on = [aws_controltower_baseline.ou]
}
