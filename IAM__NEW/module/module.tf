variable "iam_groups" {
  description = "List of IAM groups configuration"
  type        = list(object({
    name        = string
    users       = list(string)
    admin       = bool
    ec2_stop    = bool
    policy_file = string
  }))
}

variable "policy_base" {
  description = "Base path for policy files"
  type        = string
}

resource "aws_iam_group" "iam_group" {
  for_each = { for group in var.iam_groups : group.name => group }

  name = each.value.name
  depends_on = [aws_iam_user.iam_user] 
}

resource "aws_iam_user" "iam_user" {
  for_each = toset(flatten([ for group in var.iam_groups : group.users ]))

  name = each.value
  depends_on = [var.iam_groups] 
}

resource "aws_iam_policy" "admin_policy" {
  for_each = { for group in var.iam_groups : group.name => group if group.admin }

  name        = "${each.value.name}-admin-policy"
  description = "Admin Policy for ${each.value.name}"
  policy      = file("${var.policy_base}/admin-policy.json")
  depends_on = [aws_iam_group.iam_group] 
}

resource "aws_iam_policy" "developer_policy" {
  for_each = { for group in var.iam_groups : group.name => group if group.ec2_stop }

  name        = "${each.value.name}-developer-policy"
  description = "EC2 Stop Policy for ${each.value.name}"
  policy      = file("${var.policy_base}/developer-policy.json")
  depends_on = [aws_iam_policy.admin_policy] 
}

resource "aws_iam_group_membership" "group_membership" {
  for_each = { for group in var.iam_groups : group.name => group }

  name = "${each.value.name}-membership"

  users = each.value.users
  group = aws_iam_group.iam_group[each.value.name].name

  depends_on = [aws_iam_policy.developer_policy] 
}

resource "aws_iam_group_policy_attachment" "admin_group_policy_attachment" {
  for_each = { for group in var.iam_groups : group.name => group if group.admin }

  group      = each.key
  policy_arn = aws_iam_policy.admin_policy[each.key].arn
  depends_on = [aws_iam_group_membership.group_membership]
}

resource "aws_iam_group_policy_attachment" "developer_group_policy_attachment" {
  for_each = { for group in var.iam_groups : group.name => group if group.ec2_stop }

  group      = each.key
  policy_arn = aws_iam_policy.developer_policy[each.key].arn

  depends_on = [aws_iam_group_policy_attachment.admin_group_policy_attachment]
}

output "user_names" {
  value = [for user_key, user in aws_iam_user.iam_user : user.name]
  # Alternatively, you can use: value = aws_iam_user.iam_user[*].name

  depends_on = [ aws_iam_user.iam_user ]
}