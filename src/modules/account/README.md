<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_contacts"></a> [contacts](#input\_contacts) | Contact information applied to the account. Callers should normally pass<br/>the root module's var.contacts unchanged; supply a custom object only if<br/>this account needs different contact details. | <pre>object({<br/>    primary = object({<br/>      full_name          = string<br/>      company_name       = string<br/>      address_line_1     = string<br/>      address_line_2     = optional(string)<br/>      city               = string<br/>      state_or_region    = string<br/>      postal_code        = string<br/>      country_code       = string # ISO-3166 two-letter code, e.g. "US"<br/>      phone_number       = string # E.164 format, e.g. "+15555550100"<br/>      website_url        = optional(string)<br/>      district_or_county = optional(string)<br/>    })<br/>    billing = object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    })<br/>    operations = object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    })<br/>    security = object({<br/>      name          = string<br/>      title         = string<br/>      email_address = string<br/>      phone_number  = string<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_email"></a> [email](#input\_email) | Root email for the account. Must be unique across all of AWS. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Account display name, e.g. Log\_Archive | `string` | n/a | yes |
| <a name="input_opt_in_regions"></a> [opt\_in\_regions](#input\_opt\_in\_regions) | Opt-in regions to enable in the account. Callers should probably always<br/>pass the root module's local.opt\_in\_regions unchanged so every account<br/>gets a uniform set. | `list(string)` | n/a | yes |
| <a name="input_parent_id"></a> [parent\_id](#input\_parent\_id) | ID of the organizational unit the account is placed in. | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Cross-account access role Organizations creates in the account. Callers<br/>should probably always pass the root module's local.org\_access\_role<br/>unchanged. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_arn"></a> [account\_arn](#output\_account\_arn) | ARN of the member account. |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | ID of the member account. |
| <a name="output_email"></a> [email](#output\_email) | Root email assigned to the account. |
<!-- END_TF_DOCS -->