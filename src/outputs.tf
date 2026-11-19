output "organization_id" {
  description = "AWS Organization ID."
  value       = aws_organizations_organization.this.id
}

output "organization_root_id" {
  description = "ID of the organization root."
  value       = local.org_root_id
}

output "accounts" {
  description = "Member accounts, by project."
  value = {
    "Core: Log_Archive"     = module.acct_log_archive.account_id
    "Core: Audit"           = module.acct_audit.account_id
    "Core: Shared_Services" = module.acct_shared_services.account_id
    "Workload: Dev"         = module.acct_workload_dev.account_id
    "Workload: Prod"        = module.acct_workload_prod.account_id
    "Workload: Sandbox"     = module.acct_workload_sandbox.account_id
  }
}
