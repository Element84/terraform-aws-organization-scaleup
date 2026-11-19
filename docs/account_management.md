# Overview

Managing AWS accounts in an AWS Organization is critical to the security posture of your AWS ecosystem. This document describes the process for provisioning new accounts with the org.

## Core Accounts vs. Project Accounts

We can categorize AWS accounts into two types: core, and project. Core accounts include:

- Management Account
- Audit Account
- Log_Archive Account
- Shared_Services Account

Project accounts are, as the name suggests, specific to a particular project or team within your organization. This repository ships with one example project, named `workload`. It includes:

- Workload_Sandbox Account
- Workload_Dev Account
- Workload_Prod Account

## New Projects

New account(s) are most commonly requested when a new project arises. When this occurs, it's recommended that a prefix e.g. `workload` be used in account naming. Over time, as your AWS Organization grows, this naming schema makes account management much easier to maintain.

## Steps to Create a New Account

- Determine if the account is part of an existing project, or if it's part of a new project.
  - If a new project, decide on a project prefix. Create a new file `accounts_<prefix>.tf`
  - Else, use one of the existing accounts_ files.
- Determine which OU the account should be placed in.
- In the `accounts_<prefix>.tf` file, add a new module pointing to source = "./modules/account_factory". The account is created through Control Tower Account Factory, which provisions at most five accounts at a time. Use an existing module as a blueprint for the new module, ensuring each property is set correctly.
- Add the account to the root `output "accounts"` in `outputs.tf`
- In `service_guardduty.tf`, add the module to the `depends_on` list on `aws_guardduty_detector.audit`
- Grant users access to the new account via IAM Identity Center
  - In `service_identitycenter.tf`, add an `aws_ssoadmin_account_assignment` to the OrgAdmins group to allow superadmin access to the account
  - Do the same for any other user groups which should have access to the account
- Recommendation: search the entire project for an existing account pointer, e.g. `module.acct_workload_dev` and review where it is referenced. This list here may become outdated; your search may surface other places where the code should reference th account.
- Deploy these changes via Terraform
