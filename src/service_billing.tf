# -----------------------------------------------------------------------------
# Billing guardrails, in the management (payer) account so they cover spend
# for every account in the organization. Three complementary mechanisms:
#
#   - An org-wide monthly cost budget: notification at percentages of actual
#     spend, *and* when forecasted month-end spend exceeds a particular %
#     (the early warning - it fires mid-month, before the overage happens).
#   - Cost Anomaly Detection: a daily email digest of abrupt per-service
#     spend changes. Budgets are evaluated only a few times a day against
#     already-lagging billing data; anomaly detection is the faster tripwire
#     for runaway resources, and catches them even while total spend is
#     still under budget.
#   - Cost Optimization Hub: org-wide recommendations for structural waste
#     (idle resources, rightsizing, commitments) - the slow-burn counterpart
#     to the reactive alarms above. Free, like the other two.
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "org_monthly" {
  name         = "${var.rsc_name}-org-monthly"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"

  # Thresholds at which to notify based on *actual* spend. Every notification
  # fires once per month when first crossed, then resets next period.
  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.cost_notifications
  }

  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 110
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.cost_notifications
  }

  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 120
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.cost_notifications
  }

  # Alert when our *forecasted* spend is > 100% of the budget amount.
  notification {
    notification_type          = "FORECASTED"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.cost_notifications
  }
}

# The standard "AWS services" monitor: watches org-wide spend segmented per
# service, which is where anomalies are actually visible. Its ML baseline
# learns our normal spend rhythm, so ordinary variance doesn't register.
resource "aws_ce_anomaly_monitor" "services" {
  name              = "${var.rsc_name}-org-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

# Email billing stakeholders a daily digest when cost anomalies are detected.
resource "aws_ce_anomaly_subscription" "daily" {
  name      = "${var.rsc_name}-org-daily-digest"
  frequency = "DAILY"
  monitor_arn_list = [
    aws_ce_anomaly_monitor.services.arn
  ]

  dynamic "subscriber" {
    for_each = var.cost_notifications

    content {
      type    = "EMAIL"
      address = subscriber.value
    }
  }

  # Suppress trivial anomalies: the digest only includes those with a total
  # cost impact of at least $100.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["100"]
    }
  }
}

# --- Cost Optimization Hub ----------------------------------------------------

# Org-wide enrollment: include_member_accounts covers every current and
# future account from the payer. A global service homed in us-east-1; the
# provider routes to it automatically, as with the Cost Explorer resources
# above.
#
# Destroying this resource really unenrolls the organization; it is not a
# state-only removal. Recommendations regenerate within ~24h of re-enrolling,
# so the guard below is less about data and more about making sure org-wide
# cost visibility can't be switched off as a refactoring side effect (e.g. a
# rename without a moved block, planned as destroy-and-recreate). If
# unenrollment is ever intended, remove the lifecycle line in the same commit
# as the resource.
resource "aws_costoptimizationhub_enrollment_status" "org" {
  include_member_accounts = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [aws_organizations_organization.this]
}

# Both preferences set explicitly to document intent. AfterDiscounts makes
# estimated savings reflect what the payer actually saves under current
# discounts; All lets member accounts see those discounted figures too.
resource "aws_costoptimizationhub_preferences" "this" {
  savings_estimation_mode            = "AfterDiscounts"
  member_account_discount_visibility = "All"

  depends_on = [aws_costoptimizationhub_enrollment_status.org]
}

# Compute Optimizer feeds the rightsizing recommendations that Cost
# Optimization Hub imports; without it, the hub only sees idle-resource and
# commitment savings. Enrollment is account-global (all regions analyzed) and
# free on defaults - recommendation preferences are deliberately unmanaged,
# as the notable ones (e.g. 93-day enhanced infrastructure metrics) are paid.
# EC2 memory rightsizing additionally needs the CloudWatch agent publishing
# memory metrics; without it recommendations are CPU/network-based.
#
# As with the hub above, destroying this resource opts the organization back
# out, and the guard exists for the same reason (recommendations themselves
# re-derive from CloudWatch history on re-enrollment).
resource "aws_computeoptimizer_enrollment_status" "org" {
  status                  = "Active"
  include_member_accounts = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [aws_organizations_organization.this]
}
