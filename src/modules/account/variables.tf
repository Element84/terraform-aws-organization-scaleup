variable "name" {
  description = "Account display name, e.g. Log_Archive"
  type        = string
}

variable "email" {
  description = "Root email for the account. Must be unique across all of AWS."
  type        = string
}

variable "parent_id" {
  description = "ID of the organizational unit the account is placed in."
  type        = string
}

variable "contacts" {
  description = <<-EOT
    Contact information applied to the account. Callers should normally pass
    the root module's var.contacts unchanged; supply a custom object only if
    this account needs different contact details.
  EOT
  type = object({
    primary = object({
      full_name          = string
      company_name       = string
      address_line_1     = string
      address_line_2     = optional(string)
      city               = string
      state_or_region    = string
      postal_code        = string
      country_code       = string # ISO-3166 two-letter code, e.g. "US"
      phone_number       = string # E.164 format, e.g. "+15555550100"
      website_url        = optional(string)
      district_or_county = optional(string)
    })
    billing = object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    })
    operations = object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    })
    security = object({
      name          = string
      title         = string
      email_address = string
      phone_number  = string
    })
  })
}

variable "opt_in_regions" {
  description = <<-EOT
    Opt-in regions to enable in the account. Callers should probably always
    pass the root module's local.opt_in_regions unchanged so every account
    gets a uniform set.
  EOT
  type        = list(string)
}

variable "role_name" {
  description = <<-EOT
    Cross-account access role Organizations creates in the account. Callers
    should probably always pass the root module's local.org_access_role
    unchanged.
  EOT
  type        = string
}
