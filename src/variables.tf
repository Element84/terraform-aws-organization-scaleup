variable "rsc_name" {
  description = <<-EOT
    Resource naming prefix. Do not change it after initial provisioning; doing
    so would cause resource clobbering.
  EOT
  type        = string

  # Lowercase-only so the prefix is safe in names that require it, such as
  # S3 buckets. The 12-character cap keeps names readable and leaves room for
  # longer derived names.
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,11}$", var.rsc_name))
    error_message = "rsc_name must be lowercase alphanumeric or hyphens, start with an alphanumeric character, and be at most 12 characters."
  }
}

variable "base_email" {
  description = <<-EOT
    Base email used to derive unique root emails for every member account
    via plus-addressing: {user}+{account}@{domain}. Example:
    { user = "aws", domain = "example.com" } becomes
    aws+log-archive-acct@example.com, aws+audit-acct@example.com, and so on.
    All mail is delivered to the base inbox (aws@example.com).
  EOT
  type = object({
    user   = string # the part before the @
    domain = string # the part after the @
  })

  validation {
    condition     = !strcontains(var.base_email.user, "@") && !strcontains(var.base_email.domain, "@") && strcontains(var.base_email.domain, ".")
    error_message = "base_email.user and base_email.domain must not contain '@', and domain must contain a '.' (e.g. example.com)."
  }
}

variable "log_retention_days" {
  description = <<-EOT
    Days Control Tower keeps the organization's CloudTrail and AWS Config logs
    in the Log_Archive account before deleting them.
  EOT
  type        = number
  default     = 1825 # 5 years
}

variable "home_region" {
  description = "Primary AWS region for the organization (org-level resources, Control Tower, Identity Center)."
  type        = string
}

variable "securityhub_aggregation_region" {
  description = <<-EOT
    Region where Security Hub collects findings from every account and region.
    If your home_region is one that is enabled by default within AWS, you
    can leave this variable value null and your home_region will be used.

    If your home_region is an opt-in AWS region, you'll need to set this
    to a default-enabled region. Make a decision before your first apply;
    changing this later would replace the aggregator and the notification
    rules, and existing aggregated findings do not move.
  EOT
  type        = string
  default     = null
}

variable "allowed_regions" {
  description = <<-EOT
    Regions where our work happens. Must include home_region.
    Control Tower governs exactly these regions, so each must be a region
    where Control Tower is available. Opt-in regions listed here are
    automatically enabled in every member account (see regions.tf), and
    GuardDuty covers all default-enabled regions plus everything listed here.
    Nothing blocks work in other regions until the region-deny control is
    promoted (see staged/service_controltower_controls.tf).
  EOT
  type        = list(string)

  validation {
    condition     = contains(var.allowed_regions, var.home_region)
    error_message = "allowed_regions must include home_region: Control Tower must govern its own home region."
  }
}

variable "contacts" {
  description = <<-EOT
    Contact information applied to every account in the organization.
    - primary: the account's primary (root) contact details
    - billing / operations / security: alternate contacts AWS uses for
      notifications in each area
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

variable "monthly_budget_usd" {
  description = <<-EOT
    Organization-wide monthly cost budget in USD. Every address in
    var.cost_notifications is notified when actual spend reaches the budget's
    limits and when forecasted spend outpaces it (see service_billing.tf).
    Consider starting at the expected monthly cost, to confirm notifications
    arrive, then raising it a few months later once budgets are known to
    work.
  EOT
  type        = number

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd must be greater than zero."
  }
}

variable "rootmgmt_account_id" {
  description = <<-EOT
    The management account ID, as a one-item list. Guards against applying
    to the wrong account. Set it through the environment, for example:
    export TF_VAR_rootmgmt_account_id='[ "123456789012" ]'
  EOT
  type        = list(string)
}

variable "security_notifications" {
  description = <<-EOT
    Email addresses notified of important security findings aggregated by
    Security Hub (see service_securitynotifications.tf). Each address must
    confirm its SNS subscription once, via a link emailed on first apply,
    before notifications arrive.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.security_notifications) > 0
    error_message = "security_notifications must contain at least one email address"
  }
}

variable "cost_notifications" {
  description = <<-EOT
    Email addresses notified of cost and billing alerts: the monthly budget
    and cost anomalies. Keep this list current so the team hears about
    unexpected costs promptly.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.cost_notifications) > 0
    error_message = "cost_notifications must contain at least one email address"
  }
}
