## Quickstart

- Install [tfenv](https://github.com/tfutils/tfenv)
- In the `src` folder, run `tfenv install`. This will use the `.terraform-version` file to install Terraform.
- Install [pre-commit](https://github.com/pre-commit/pre-commit)
- In the project root folder, install the pre-commit hooks: `pre-commit install`
- Make your changes and open a PR! We appreciate your help :)

**Testing**

The nature of this codebase, building your foundation in AWS, requires care in development. We ask that you test your changes to the best of your ability, and describe how you've tested the change in the description of your PR.

## Useful Dev Commands

```bash
# run all pre-commit checks
pre-commit run --all-files

# update READMEs via terraform-docs
pre-commit run terraform-docs-go --all-files

# tflint everything
pre-commit run terraform_tflint --all-files

# terraform format everything
terraform fmt --recursive
```
