<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acct_audit"></a> [acct\_audit](#module\_acct\_audit) | ./modules/account | n/a |
| <a name="module_acct_log_archive"></a> [acct\_log\_archive](#module\_acct\_log\_archive) | ./modules/account | n/a |
| <a name="module_acct_shared_services"></a> [acct\_shared\_services](#module\_acct\_shared\_services) | ./modules/account_factory | n/a |
| <a name="module_acct_workload_dev"></a> [acct\_workload\_dev](#module\_acct\_workload\_dev) | ./modules/account_factory | n/a |
| <a name="module_acct_workload_prod"></a> [acct\_workload\_prod](#module\_acct\_workload\_prod) | ./modules/account_factory | n/a |
| <a name="module_acct_workload_sandbox"></a> [acct\_workload\_sandbox](#module\_acct\_workload\_sandbox) | ./modules/account_factory | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_regions"></a> [allowed\_regions](#input\_allowed\_regions) | Regions where our work happens. Must include home\_region.<br/>Control Tower governs exactly these regions, so each must be a region<br/>where Control Tower is available. Opt-in regions listed here are<br/>automatically enabled in every member account (see regions.tf), and<br/>GuardDuty covers all default-enabled regions plus everything listed here.<br/>Nothing blocks work in other regions until the region-deny control is<br/>promoted (see staged/service\_controltower\_controls.tf). | `list(string)` | n/a | yes |
| <a name="input_base_email"></a> [base\_email](#input\_base\_email) | Base email used to derive unique root emails for every member account<br/>via plus-addressing: {user}+{account}@{domain}. Example:<br/>{ user = "aws", domain = "example.com" } becomes<br/>aws+log-archive-acct@example.com, aws+audit-acct@example.com, and so on.<br/>All mail is delivered to the base inbox (aws@example.com). | <pre>object({<br/>    user   = string # the part before the @<br/>    domain = string # the part after the @<br/>  })</pre> | n/a | yes |
| <a name="input_contacts"></a> [contacts](#input\_contacts) | Contact information applied to every account in the organization.<br/>- primary: the account's primary (root) contact details<br/>- billing / operations / security: alternate contacts AWS uses for<br/>  notifications in each area | <pre>object({<br/>    primary = object({<br/>      full_name          = string<br/>      company_name       = string<br/>      address_line_1     = string<br/>      address_line_2     = optional(string)<br/>      city               = string<br/>      state_or_region    = string<br/>      postal_code        = string<br/>      country_code       = string # ISO-3166 two-letter code, e.g. "US"<br/>      phone_number       = string # E.164 format, e.g. "+15555550100"<br/>      website_url        = optional(string)<br/>      district_or_county = optional(string)<br/>    })<br/>    billing = object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    })<br/>    operations = object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    })<br/>    security = object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_cost_notifications"></a> [cost\_notifications](#input\_cost\_notifications) | Email addresses notified of cost and billing alerts: the monthly budget<br/>and cost anomalies. Keep this list current so the team hears about<br/>unexpected costs promptly. | `list(string)` | n/a | yes |
| <a name="input_home_region"></a> [home\_region](#input\_home\_region) | Primary AWS region for the organization (org-level resources, Control Tower, Identity Center). | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Days Control Tower keeps the organization's CloudTrail and AWS Config logs<br/>in the Log\_Archive account before deleting them. | `number` | `1825` | no |
| <a name="input_monthly_budget_usd"></a> [monthly\_budget\_usd](#input\_monthly\_budget\_usd) | Organization-wide monthly cost budget in USD. Every address in<br/>var.cost\_notifications is notified when actual spend reaches the budget's<br/>limits and when forecasted spend outpaces it (see service\_billing.tf).<br/>Consider starting at the expected monthly cost, to confirm notifications<br/>arrive, then raising it a few months later once budgets are known to<br/>work. | `number` | n/a | yes |
| <a name="input_rootmgmt_account_id"></a> [rootmgmt\_account\_id](#input\_rootmgmt\_account\_id) | The management account ID, as a one-item list. Guards against applying<br/>to the wrong account. Set it through the environment, for example:<br/>export TF\_VAR\_rootmgmt\_account\_id='[ "123456789012" ]' | `list(string)` | n/a | yes |
| <a name="input_rsc_name"></a> [rsc\_name](#input\_rsc\_name) | Resource naming prefix. Do not change it after initial provisioning; doing<br/>so would cause resource clobbering. | `string` | n/a | yes |
| <a name="input_security_notifications"></a> [security\_notifications](#input\_security\_notifications) | Email addresses notified of important security findings aggregated by<br/>Security Hub (see service\_securitynotifications.tf). Each address must<br/>confirm its SNS subscription once, via a link emailed on first apply,<br/>before notifications arrive. | `list(string)` | n/a | yes |
| <a name="input_securityhub_aggregation_region"></a> [securityhub\_aggregation\_region](#input\_securityhub\_aggregation\_region) | Region where Security Hub collects findings from every account and region.<br/>If your home\_region is one that is enabled by default within AWS, you<br/>can leave this variable value null and your home\_region will be used.<br/><br/>If your home\_region is an opt-in AWS region, you'll need to set this<br/>to a default-enabled region. Make a decision before your first apply;<br/>changing this later would replace the aggregator and the notification<br/>rules, and existing aggregated findings do not move. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_accounts"></a> [accounts](#output\_accounts) | Member accounts, by project. |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | AWS Organization ID. |
| <a name="output_organization_root_id"></a> [organization\_root\_id](#output\_organization\_root\_id) | ID of the organization root. |
<!-- END_TF_DOCS -->