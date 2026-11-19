# OIDC for github actions Terraform apply, in the repository that holds this code
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# IAM Role for github actions in the repository that holds this code
resource "aws_iam_role" "github_deploy_role" {
  name = "github-actions-deploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Restrict exclusively to our repository.
          # TODO: replace the organization, the repository, and the numeric
          # GitHub ID after each with your own.
          "token.actions.githubusercontent.com:sub" = "repo:example-org@12345678/terraform-aws-organization-scaleup@1234567890:*"
        }
      }
    }]
  })
}

# Terraform unfortunately needs wide permissions across the AWS organization. CI/CD
# should be tightly locked down.
resource "aws_iam_role_policy_attachment" "github_deploy_role_admin" {
  role       = aws_iam_role.github_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
