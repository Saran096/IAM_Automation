provider "aws" {
  region = "ap-south-1"
}

module "iam" {
  source      = "./module"
  iam_groups  = local.config_files.iam_groups
  policy_base = local.config_files.policy_base
}

output "iam_user_names" {
  value = module.iam.user_names
}
