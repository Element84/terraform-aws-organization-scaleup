# terraform-aws-organization-scaleup

> 🚧 **Under Construction** 🚧
> 
> We're actively working toward a v1. For now, we recommend only using this repository for Use Case 2 outlined below. We'd hold off on Use Cases 1 and 3 until v1, which we're working to release.

If you've been tasked with setting up AWS for a growing organization, this repository is for you. It's designed to give your team a secure, multi-account AWS environment with cost controls and org-wide guardrails following AWS's prescriptive best practices, built on AWS Control Tower. We aim to make it as easy as possible to set up and maintain via Terraform with a comprehensive step-by-step setup guide [/docs/0_setup.md](docs/0_setup.md).

> If your team is small and doesn't expect to create AWS accounts often, see the [terraform-aws-organization-lean vs. terraform-aws-organization-scaleup vs. Enterprise](#terraform-aws-organization-lean-vs-terraform-aws-organization-scaleup-vs-enterprise) section below and our [terraform-aws-organization-lean](https://github.com/Element84/terraform-aws-organization-lean) repository.

AWS calls this a "landing zone," a well-architected, multi-account environment that is a secure, reliable starting point for your workloads. This repository builds your AWS landing zone: accounts, organizational units, user access, security monitoring, guardrails, and cost alerts, all configured under a single AWS Organization. AWS Control Tower governs the landing zone, and new accounts are created through its Account Factory.

## Use Cases

The guides in [/docs](docs/) refer to these use cases by number.

### You already have one or more AWS accounts

- **Use Case 1: build a new AWS Organization, import your existing accounts**
  - If you have existing AWS workloads but never configured a proper landing zone in AWS Organizations, use this repository to create a new best-practices landing zone from scratch. Then enroll your existing accounts into that landing zone.
- **Use Case 2: compare your existing AWS Organization with this one, surface areas for improvement**
  - If your team has a multi-account AWS landing zone in place via AWS Organizations or AWS Control Tower, use this repository to compare and contrast what you've built.

### You're starting from scratch in AWS

- **Use Case 3: provision a new AWS Organization and start building in it**
  - Use this repository to set up AWS from scratch for your team. You'll get an AWS landing zone fully prepared to host your workloads, from development to production.

## Getting Started

### Build Your AWS Organization

1. We recommend everyone read the [terraform-aws-organization-lean vs. terraform-aws-organization-scaleup vs. Enterprise](#terraform-aws-organization-lean-vs-terraform-aws-organization-scaleup-vs-enterprise) section below.

2. If you fall under Use Case 1 or 3 defined above, follow the setup guide in [/docs/0_setup.md](docs/0_setup.md).
   - There is some preparation involved, and you'll use Terraform to build via code rather than manually clicking around the AWS console.
   - The setup guide specifically calls out when you should turn to the other [/docs](docs/) for additional reading. We attempt to keep the docs clear and concise, so reading them at any time may be worthwhile.

3. If you fall under Use Case 2, an LLM might be helpful to synthesize what this repository builds.

### Ongoing Maintenance

Maintaining your team's AWS environment does require some ongoing work. We've created a maintenance guide [/docs/1_maintenance.md](docs/1_maintenance.md) to help you down the road.

## Organizational Structure

Multiple AWS accounts governed by AWS Organizations (which is an AWS service, not just terminology) is a best practice. Accounts and their containers, Organizational Units (OUs), are very easy to create, so there is little overhead but significant benefit to separating concerns. This project builds a single AWS Organization with this structure:

```
Organization Root
├── Management Account
├── Security OU
│   ├── Log_Archive Account
│   └── Audit Account
├── Infrastructure OU
│   └── Shared_Services Account
├── Workloads OU
│   ├── Workload_Dev Account
│   └── Workload_Prod Account
└── Sandbox OU
    └── Workload_Sandbox Account
```

[/docs/accounts_services.md](docs/accounts_services.md) describes each account's primary purpose.

Accounts within the Workloads and Sandbox OUs can be adjusted to your needs. For example, you may want to give each of your developers their own individual sandbox account, or you may want a dev-staging-prod rather than dev-prod configuration. The setup guide [/docs/0_setup.md](docs/0_setup.md) notes these choices, and [/docs/account_management.md](docs/account_management.md) digs into detail.

## AWS Control Tower and Account Factory

AWS Control Tower is a managed service that sits on top of AWS Organizations. You describe the landing zone you want, and Control Tower sets it up and keeps watch over it. In this repository, Control Tower provides:

- **Central logging.** An organization-wide CloudTrail trail and AWS Config recording in every account, delivered to the Log_Archive account.
- **Controls.** Control Tower's name for guardrails. It applies a mandatory set to every account, and you can turn on more from its library with a few lines of Terraform, rather than writing each policy by hand.
- **Drift detection.** Control Tower reports when an account or OU no longer matches the landing zone.
- **Account Factory.** Every new account is created the same way and arrives with logging, controls, and your baseline already in place.

The landing zone, its controls, and every account are defined in Terraform. Avoid changing anything Control Tower manages by hand in the console; it will be reported as drift.

## AWS Service Overview

A number of AWS services are critical to the management of your landing zone. This table lists those core AWS services and the account you'll access them from (the account the service is "delegated" to; see [/docs/accounts_services.md](docs/accounts_services.md) for more detail). Some services, like AWS Organizations and org-wide billing, cannot be delegated, meaning you'll use the Management Account to access them:

| Service | Acct Delegated To | Description |
| --- | --- | --- |
| AWS Organizations | N/A | OUs, member accounts, org policies, centralized root access |
| AWS Control Tower | N/A | The landing zone, its controls, drift detection, and Account Factory |
| Billing & Cost Management | N/A | Org budget, cost anomaly alerts, cost optimization recommendations |
| IAM Identity Center | Shared_Services | User access management: users, groups, permission sets, account assignments |
| Security Hub CSPM | Audit | Security posture: aggregates findings org-wide into a single console |
| GuardDuty | Audit | Threat detection in every account and enabled region |
| IAM Access Analyzer | Audit | External-access analysis across the organization, plus an account-level analyzer in the Management Account |
| AWS Config | Audit | Records resource configuration in every account, set up by Control Tower |
| Incident Response | Audit | Monitor and triage security findings across the organization |

## terraform-aws-organization-lean vs. terraform-aws-organization-scaleup vs. Enterprise

Is the approach we take a good fit for your team? We've found that teams tend to need one of three levels of landing zone: Lean, Scaleup, or Enterprise. We provide solutions for the first two, and AWS provides a solid approach for the third.

### [terraform-aws-organization-lean](https://github.com/Element84/terraform-aws-organization-lean)

- Smaller, agile teams
- Don't expect to create new AWS accounts frequently

The `-lean` repository does *not* use AWS Control Tower and does *not* use Account Factory. For lean, agile teams, we think the added complexity of Control Tower and Account Factory outweighs their benefits.

### terraform-aws-organization-scaleup (this repository)

- Larger teams, with more resources to dedicate to AWS landing zone configuration and maintenance
- May expect to create new AWS accounts with some frequency

The primary technical difference between this `-scaleup` and the `-lean` repository: this repository *does* utilize both AWS Control Tower and Account Factory, whereas the `-lean` repository does not. They add a layer of complexity, but provide benefits in guardrail and account management.

### Enterprise

- Teams with a dedicated IT group responsible for maintaining cloud environments
- Highly regulated industries, stringent compliance requirements

For enterprises and teams with highly regulated workloads or complex compliance requirements, we recommend AWS's Landing Zone Accelerator with its Universal Configuration option: [https://github.com/aws/lza-universal-configuration](https://github.com/aws/lza-universal-configuration)

## Architectural Approach

Two guiding principles:

1. Make management of an AWS landing zone as easy as possible for growing teams

2. Follow AWS Well-Architected best practices

The approaches described in the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/framework.html), [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/introduction.html), and [Organizing Your AWS Environment Using Multiple Accounts](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html) are important references.

## Special Thanks

Maintaining this solution would not be possible without help from numerous engineers at [Element 84](https://element84.com) and our management team. We'd especially like to thank [Digital Earth Africa](https://digitalearthafrica.org), who worked with us to develop the original version.
