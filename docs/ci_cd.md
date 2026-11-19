# Overview

This repository includes GitHub Actions workflows that plan and apply your Terraform changes. They are optional: you can run Terraform from a workstation, or build your own CI/CD. Whichever you choose, extreme care should be taken to #1 ensure only highly trusted team members have access to your repository and its ability to configure your AWS environment and #2 verify each change carefully before deploying it.

The workflows are not active by default. They ship in `/src/staged/github`, where GitHub ignores them.

## What the Workflows Do

- `tf_plan.yaml` runs on every pull request to main. It runs the pre-commit checks and a `terraform plan`, posts the plan as a comment on the pull request, and saves the plan file.
- `tf_apply.yaml` runs when a pull request is merged to main. It downloads the plan file saved by that pull request and applies exactly that plan.
- `reusable-precommit.yml` holds the pre-commit checks used by `tf_plan.yaml`.

The workflows sign in to AWS as the `github-actions-deploy-role` in your Management Account, created by `src/service_iam.tf`. No AWS access keys are stored in GitHub.

## Turning Them On

Do this after your first `terraform apply` (see the [setup guide](0_setup.md)), because that apply creates the role the workflows use.

- [ ] In `src/service_iam.tf`, confirm the `TODO:` is done: the role must name your GitHub organization and repository, or AWS will refuse the workflows. Apply the change if you made one.

- [ ] Delete the `/.github` directory. It holds this project's own checks, which you don't need.

- [ ] Copy `/src/staged/github` to the repository root and rename it `.github`.

- [ ] In your GitHub repository settings, add a repository secret named `TF_VAR_rootmgmt_account_id` holding your Management Account ID, and a repository variable named `AWS_REGION` holding your `home_region`.

- [ ] Open a pull request to confirm a plan is posted as a comment.

## Securing the Pipeline

The deploy role has administrator access to your Management Account, and any workflow in your repository can use it. **Treat write access to the repository as administrator access to your whole AWS Organization!**

- [ ] Keep the repository private, and give write access to as few people as possible.

- [ ] Protect the main branch: require a pull request and an approving review before merging, and require the plan workflow to pass.

- [ ] Require review from your Core Infrastructure and Security team for any change under `/.github`, using a CODEOWNERS file.

## Deploying a Change

- Create a branch from main. Make changes to that branch. If your commit fails due to pre-commit checks, run `pre-commit run --all-files` to get details on which check(s) require changes to your code.
- Open a PR to main. A GitHub Action will run pre-commit checks, and importantly, it will terraform plan (storing the output into a plan file). When that completes, the GitHub Action will add a comment to the PR detailing the output of the terraform plan. **Review this plan very carefully.**
  - Note that any pushes to the PR will re-run the terraform plan step; once complete, the previous PR comment containing the previous plan is automatically deleted, and a new comment with the new plan inserted.
- When you're happy with the terraform plan's output, merge the PR. A GitHub Action will download the terraform plan file from the PR, and terraform apply exactly that plan file.
- **Important:** after merging to main, check the GitHub Actions UI to ensure the terraform apply step completes successfully. If it fails for any reason, your changes may not have been applied to the AWS environment!

If another change was applied after your plan was created, Terraform rejects your plan as stale and the apply fails. Merge one PR at a time, and update your branch so the plan re-runs before you merge.
