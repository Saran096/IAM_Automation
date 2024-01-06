locals {
  example_local_variable = "example_local_value"
  config_files = {
    iam_groups = [
      {
        name        = "admin"
        users       = ["user1", "user2", "user5"]
        admin       = true
        ec2_stop    = false
        policy_file = "./policies/admin-policy.json"
      },
      {
        name        = "ec2_stop"
        users       = ["user3", "user4"]
        admin       = false
        ec2_stop    = true
        policy_file = "./policies/developer-policy.json"
      },
      # Add more IAM group configurations as needed
    ]
    policy_base = "${path.module}/policies" # Use path.module to reference the current module's directory
  }
}
