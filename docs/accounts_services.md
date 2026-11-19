# Overview

This document describes what each AWS account is for, and which account you use to work with each of the core services. The [README](../README.md) shows how the accounts are arranged into Organizational Units.

## Accounts

### Management Account

The account that owns the AWS Organization and pays the bill. It holds:

- AWS Organizations itself: OUs, member accounts, and guardrails
- AWS Control Tower: the landing zone, its controls, and Account Factory
- Billing: the org-wide budget, cost anomaly alerts, and Cost Optimization Hub
- The organization's CloudTrail trail (the logs themselves are stored in Log_Archive)
- The Terraform state bucket, and the role your CI/CD uses to deploy this code

Guardrails (Control Tower controls) do not apply to the Management Account, so nothing limits what a compromised login can do here. Never run workloads in it, give access only to your Core Infrastructure and Security team, and sign in to it only when a task can't be done anywhere else.

### Log_Archive Account

Stores the CloudTrail and AWS Config logs for the whole organization: a record of management activity (who created, changed or deleted what) and of how every resource is configured, in every account and governed region. Control Tower creates and manages the log buckets, and keeps the logs for 5 years by default (`log_retention_days`).

Almost nobody needs access to this account. You'll use it when investigating an incident, or answering "who did this, and when?"

### Audit Account

Where your security team works. The security services are delegated here, so findings from every account arrive in one place:

- Security Hub CSPM collects findings from every account and region
- GuardDuty detects threats
- IAM Access Analyzer reports resources shared outside the organization
- AWS Config's organization-wide view of resource configuration, set up by Control Tower
- Security Incident Response, if you enable it (see the [setup guide](0_setup.md))

This account also sends the email alerts for new critical findings, to the addresses in `security_notifications`.

### Shared_Services Account

IAM Identity Center is delegated here, so everyday user management happens in this account: adding and removing users, and assigning them to groups. See [user_management.md](user_management.md).

It's also the natural home for anything several projects share, such as a container registry or shared networking. This repository doesn't create any.

### Workload Accounts

Where your team actually builds. This repository ships with one example project, named `workload`:

- Workload_Dev and Workload_Prod, in the Workloads OU
- Workload_Sandbox, in the Sandbox OU, for experiments that shouldn't touch dev or prod

Each is created through Control Tower Account Factory, so it arrives with logging and controls in place. Members of the WorkloadDevelopers group have access to all three. Separate accounts mean a mistake in dev can't reach prod, and each account's costs appear separately on the bill. See [account_management.md](account_management.md) to add accounts or projects.

## Service Delegation

As a best practice, you should not use these services from within your Management Account; the Management Account has highly elevated org-wide privileges, so use it as little as possible and highly restrict access to it. AWS terms this "delegated administration," which simply means we take a service that's set up in the Management Account by default (e.g. IAM Identity Center) and allow an account other than the Management Account (e.g. Shared_Services Account) to utilize that service.

| To work with | Sign in to |
| --- | --- |
| OUs, accounts, guardrails, Control Tower | Management Account |
| Billing, budgets, cost recommendations | Management Account |
| Users and groups (IAM Identity Center) | Shared_Services |
| Security findings (Security Hub CSPM, GuardDuty, IAM Access Analyzer) | Audit |
| Security Incident Response | Audit |
| CloudTrail and AWS Config logs | Log_Archive |

Two limits to know about:

- Some services, like AWS Organizations and org-wide billing, cannot be delegated, which is why they stay in the Management Account.
- The superadmin permission set (OrgAdministrator) can only be changed from the Management Account, not from Shared_Services, because it grants access to the Management Account itself.
