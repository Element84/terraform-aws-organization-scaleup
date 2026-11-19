# -----------------------------------------------------------------------------
# AWS Incident Response
#
# A managed security service that monitors the AWS environment for threats,
# triages security findings automatically, and engages your team only when
# action is required. In a real incident, the AWS Security Incident Response
# team investigates, helps contain the threat, and guides recovery.
# -----------------------------------------------------------------------------

# As of Fall 2026, neither the CloudFormation Registry nor the Terraform AWS
# provider supports Incident Response's control plane, so it cannot be
# managed here.
#
# TODO: enable and configure Incident Response in the AWS console. Delegate
# its management to the Audit account, and set its security contacts to match
# var.security_notifications.
