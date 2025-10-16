# Trust policy for DEV deployments.
# This role can only be assumed by GitHub Actions workflows when running on specific branches
# or using the "dev" environment. This prevents other branches from accidentally deploying.
data "aws_iam_policy_document" "dev_trust" {
  statement {
    sid     = "AllowGitHubOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Allow assumption only when the GitHub OIDC subject matches these patterns:
    # - environment:dev (GitHub Environments)
    # - feature/infra-aws (the branch used while bootstrapping infra)
    # - deploy/* (dedicated deployment branches)
    # - develop (optional)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:egobb/order-tracking:environment:dev",
        "repo:egobb/order-tracking:ref:refs/heads/feature/infra-aws",
        "repo:egobb/order-tracking:ref:refs/heads/deploy/*",
        "repo:egobb/order-tracking:ref:refs/heads/develop"
      ]
    }

    # Standard condition required by AWS OIDC federation with GitHub.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Trust policy for PROD deployments.
# Only workflows triggered by tags starting with "v" (e.g. v1.0.0) can assume this role.
# This enforces that production deploys must come from a tagged release.
data "aws_iam_policy_document" "prod_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:egobb/order-tracking:ref:refs/tags/v*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}