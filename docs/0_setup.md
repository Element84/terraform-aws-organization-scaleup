# Overview

This guide is a step-by-step walkthrough using this repository to build out your AWS landing zone. Throughout, we'll reference differences for Use Case 1 and Use Case 3; see the [README.md](../README.md) for an explanation of the various use cases.

## Preparation

- [ ] Read through the [src/variables.tf](../src/variables.tf). We've tried to limit the number and complexity of variables to make using this project as easy as possible, while still giving teams the flexibility you need to make it useful.

- [ ] Decide on the AWS region you want to be your home. Some central managerial services will live here.

- [ ] You'll need an email address at your organization that #1 can be exclusively used for AWS purposes and #2 allows for plus addressing. Teams commonly choose `aws@myorg.com`. Plus addressing is available in nearly all email providers: `aws+account1@myorg.com`, `aws+account2@myorg.com`, `aws+account3@myorg.com`

- [ ] Identify a group of people, ideally three, who will act as your "AWS Core Infrastructure & Security Team." These need to be highly trusted individuals in your organization, they'll have root access to your AWS ecosystem.

## Preparation -- This Repository

This is a public GitHub project; it's vital that when you use it, your git repository is private and access to it is *very* tightly controlled. We provide GitHub Actions you can use to deploy this solution to your AWS environment, you may also choose to build your own CI/CD. In either case, this project will have permissions to provision infrastructure in your AWS accounts.

Note that GitHub does not allow forks of public projects to be made private.

## Initial Account Creation and Hardening

- [ ] Create an account at aws.amazon.com. Note that this becomes the organization's root Management Account! You'll need an email address, phone number, and payment details available to complete initial account setup.

- [ ] Enable MFA on the Management Account's root user, and ensure the password is strong.
  - Ideally, the Management Account root user login credentials, and associated email, are accessible to **more than one** person. This is the "AWS Core Infrastructure & Security Team." Note that AWS does allow multiple MFA devices.

- [ ] Visit Cost Explorer and enable it.

- [ ] Activate "IAM user and role access to Billing information" within the Management Account. This can be found under Account Settings.

## Our First `terraform apply`

- [ ] Create a bootstrap IAM user that will be used for initial Terraform apply (the root user should not be used). Importantly, we'll decommission this temporary user after IAM Identity Center is enabled and a real human admin has verified sign-in.

- [ ] Create an S3 bucket in the root Management Account, in the region you've chosen as your home region, for storing Terraform state. **Importantly**, enable versioning. Check that block-public-access is set and SSE is in place; these are defaults, so *should* be set without intervention.

- [ ] Edit `providers.tf`, pointing to that S3 statefile bucket.

- [ ] Review `terraform.tfvars` for accuracy.

- [ ] Carefully review every TODO: found throughout the project. You may not need to address all of them before the next step, but you should have a plan to do so.

- [ ] Confirm every region in `allowed_regions` is one where AWS Control Tower is available. Control Tower governs exactly those regions.

- [ ] Run `terraform apply`. The first apply stops when it reaches the accounts created through Account Factory, because the user running Terraform does not yet have access to it.

- [ ] In the Management Account, open Service Catalog, choose Portfolios, open "AWS Control Tower Account Factory Portfolio", and under Access grant access to the user or role that runs Terraform.

- [ ] Run `terraform apply` again to create the remaining accounts.

**Notes**

- If your home region is an opt-in region, you'll need to enable it in the AWS console. Expect the initial terraform apply may take longer than you may expect.

- Creating the Control Tower landing zone can take an hour or more, and each account created through Account Factory takes several minutes. Expect the first apply to be long.

- Re-runs are safe and somewhat expected. First applies of this shape occasionally trip on eventual consistency (assuming OrganizationAccountAccessRole into seconds-old accounts, region enablement races). If it fails partway, just run apply again.

## Verify Before Continuing

- [ ] Within the root Management Account, you should see AWS Organization, Organizational Units, Accounts (and much more -- it may be worth the time to review service_* files and verify a bit).

- [ ] Emails should have been received for each member Account provisioned.

- [ ] From the Management Account, use Switch Role into the Audit and Log_Archive accounts via OrganizationAccountAccessRole, and into the other accounts via AWSControlTowerExecution, to verify cross-account access.

- [ ] In the Control Tower console, confirm the landing zone is active with no drift, the Infrastructure, Workloads and Sandbox OUs are registered, and every account is enrolled.

- [ ] Ensure CloudTrail and AWS Config logs are flowing as expected, in the Log_Archive account.

- [ ] In the Audit account, confirm Security Hub is enabled with the cross-region aggregator active; findings from GuardDuty and Access Analyzer across all regions will appear here. No standards are enabled by design (yet), so there are no compliance scores.

## IAM Identity Center

- [ ] **Important:** before proceeding, ensure the home region is the chosen region in your console. If you click Enable before selecting the correct region, Identity Center is set up in the incorrect region.
  - [ ] Enable IAM Identity Center manually via the Management Account console, **in your home region**. This can only happen after the organization exists, which is why the Identity Center Terraform is staged in `/src/staged`.

- [ ] In Identity Center settings, a few manual changes need to be made that cannot be managed by Terraform:
  - [ ] Enable MFA enforcement
  - [ ] Set the domain URL and instance name

- [ ] Move the two Identity Center files (`service_identitycenter.tf` and `service_identitycenter_users.tf`) from `/src/staged` into `/src` and terraform apply.

## Security Incident Response

AWS Security Incident Response triages security findings across your organization, and gives you access to AWS's incident response team during a real incident. We strongly recommend enabling it. It is a paid service, so check the [pricing page](https://aws.amazon.com/security-incident-response/pricing/) first. Unfortunately, Terraform cannot manage it yet, so you'll need to manually do so via the AWS console:

- [ ] Sign in to the Management Account, open the Security Incident Response console, and choose **Sign up**.

- [ ] Choose **Use a delegated administrator account** and enter the Audit account's ID. Then sign in to the Audit account to continue.

- [ ] Select your home region, if the service is offered there. This cannot be changed later.

- [ ] Set the scope to your whole organization.

- [ ] Add at least two incident response contacts. Use the same people as `security_notifications` in `src/terraform.tfvars`.

- [ ] Confirm the permissions and choose **Sign up**.

Containment, which lets AWS act on your resources during an incident, is off by default and needs a separate deployment. See [AWS's setup guide](https://docs.aws.amazon.com/security-ir/latest/userguide/deploy-configure.html).

## Miscellaneous

- [ ] If your team wants advanced support from AWS, enable it via the AWS Console. Do this from the Management Account.

- [ ] Cleanup: ensure that the temporary "bootstrap IAM user" has been decommissioned from the root Management Account.

- [ ] Cleanup: IAM Access Analyzer's first scan creates duplicate `AWS::IAM::Role` findings in every region (the auto-archive rules only affect findings created after them). In the Audit account, bulk-archive these findings in every region except your home region — or just ignore them. Future findings deduplicate automatically.
