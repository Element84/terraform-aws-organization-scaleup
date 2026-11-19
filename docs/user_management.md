# Overview

This document details how human users are managed in your AWS environment. Historically, user access has been one of the primary causes of security incidents within AWS Organizations. Thoughtful, deliberate management of users following best practices -- short-lived credentials, least privilege, 2FA enforcement, removal of inactive users, etc. -- is essential to maintaining a secure AWS environment.

## IAM Identity Center

IAM Identity Center is the central user management hub for your AWS Organization. All user access should flow through IAM Identity center; users, even temporary users, should *not* be provisioned through IAM's legacy user featureset.

The Shared_Services account has been delegated as the adminstrator for the IAM Identity Center service; the IT team managing users should access IAM Identity Center via the Shared_Services account.

## Terraform vs. AWS Console Management

We use Terraform to manage much of IAM Identity Center, but not everything. Terraform manages:

- Superadmin users (see `service_identitycenter_users.tf`)
- User Groups and their permission sets + account access (see `service_identitycenter.tf`)

Manage the following via the AWS Console, not Terraform:

- All non-superadmin users

In a nutshell, adding a typical user is done via the AWS console: create the user and assign them to an existing user group + permission set/account access. If a new user group is required, or changes to superadmin users is required, use Terraform.

## Best Practices

- Use Groups (defined in `service_identitycenter.tf`) to manage user permissions, rather than assigning custom permissions per user.
- Keep the number of User Groups as small as feasible, while still keeping least privilege principles in mind. Create a new Group when needed, but try to avoid creating a Group for just a single user whenever possible.
- Regularly review user access, and remove inactive users promptly. Create a user management runbook for provisioning and deprovisioning users.
- Disable account root user access. We have done this at the AWS Organization level; ensure this does not change.
