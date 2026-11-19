# -----------------------------------------------------------------------------
# Security Finding Notifications
#
# Not an AWS service: a custom email pipeline for security findings.
# Addresses in var.security_notifications are emailed new Security Hub CSPM
# CRITICAL findings.
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "security_findings" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  name = "${var.rsc_name}-security-findings"
}

# EventBridge cannot publish without an explicit grant. Scoped to this rule's
# ARN so nothing else can publish to the topic.
resource "aws_sns_topic_policy" "security_findings" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  arn = aws_sns_topic.security_findings.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgePublish"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.security_findings.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.critical_findings.arn }
        }
      }
    ]
  })
}

# Each address receives a one-time confirmation email and gets nothing until
# the link is clicked. Terraform cannot delete a never-confirmed
# subscription; it expires on its own after three days.
resource "aws_sns_topic_subscription" "security_findings_email" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region
  for_each = toset(var.security_notifications)

  topic_arn = aws_sns_topic.security_findings.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_event_rule" "critical_findings" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  name        = "${var.rsc_name}-critical-security-findings"
  description = "CRITICAL Security Hub findings, org-wide via aggregation, to the security-findings SNS topic."

  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity    = { Label = ["CRITICAL"] }
        RecordState = ["ACTIVE"]
        Workflow    = { Status = ["NEW"] }
      }
    }
  })
}

# Each "Findings - Imported" event carries exactly one finding. The
# transformer turns its raw ASFF JSON into a short plaintext email; the
# subject line is fixed by SNS ("AWS Notification Message") and not
# customizable without a Lambda.
#
# The template's odd quoting is required: for multi-line string output,
# EventBridge demands each line be wrapped in its own double quotes (a bare
# multi-line string is rejected as an invalid template), and it joins the
# quoted lines with newlines when rendering.
resource "aws_cloudwatch_event_target" "critical_findings_email" {
  provider = aws.audit
  region   = local.securityhub_aggregation_region

  rule = aws_cloudwatch_event_rule.critical_findings.name
  arn  = aws_sns_topic.security_findings.arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.findings[0].Severity.Label"
      account     = "$.detail.findings[0].AwsAccountId"
      region      = "$.detail.findings[0].Region"
      title       = "$.detail.findings[0].Title"
      description = "$.detail.findings[0].Description"
    }

    input_template = <<-EOT
      "<severity> Security Hub Finding: <title>"
      "Account: <account>"
      "Region: <region>"
      "Description: <description>"
      "Review in the Security Hub console of the Audit account. Mark the finding NOTIFIED or SUPPRESSED there to stop repeat emails."
    EOT
  }
}
