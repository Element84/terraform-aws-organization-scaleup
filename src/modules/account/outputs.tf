output "account_id" {
  description = "ID of the member account."
  value       = aws_organizations_account.this.id
}

output "account_arn" {
  description = "ARN of the member account."
  value       = aws_organizations_account.this.arn
}

output "email" {
  description = "Root email assigned to the account."
  value       = aws_organizations_account.this.email
}
