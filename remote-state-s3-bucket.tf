resource "aws_s3_bucket" "terraform-github-remotestate-2021" {
  bucket = "terraform-github-remotestate-2021"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock_table" {
  hash_key = "LockID"
  name = "terraform_state_lock_table"
  attribute {
    name = "LockID"
    type = "S"
  }
  read_capacity = 20
  write_capacity = 20
}

#-----------------
# IAM policies, there are 3: s3 list, read, write and dynamodb table read, write and iam user self managed policies
#-----------------

data "aws_iam_policy_document" "terraform_s3_list_read_write_policy_document" {
  statement {
    actions = [
    "s3:*"
    ]
    resources = [
    aws_s3_bucket.terraform-github-remotestate-2021.arn,
      "${aws_s3_bucket.terraform-github-remotestate-2021.arn}/organization/terraform-heros/terraform.tfstate"
    ]
  }
}

resource "aws_iam_policy" "terraform_s3_list_read_write_policy" {
  name = "S3TerraformStateListReadWriteAccess"
  path = "/"
  description = "Grants List, Read and Write Access to the S3 terraform-github-remotestate-2021 bucket"
  policy = data.aws_iam_policy_document.terraform_s3_list_read_write_policy_document.json
}

data "aws_iam_policy_document" "terraform_dynamodb_read_write_policy_document" {
  statement {
    actions = [
    "dynamodb:*"
    ]
    resources = [
    aws_dynamodb_table.terraform_state_lock_table.arn
    ]
  }
}

resource "aws_iam_policy" "terraform_dynamodb_read_write_policy" {
  name = "DynamoDBReadWriteTerraformStateLockAccess"
  path = "/"
  description = "Allows read and write access to the dynamodb table"
  policy = data.aws_iam_policy_document.terraform_dynamodb_read_write_policy_document.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "iam_user_self_management_policy_document" {
  statement {
    actions = [
    "iam:*"
    ]
    resources = [
    aws_iam_policy.terraform_dynamodb_read_write_policy.arn,
    aws_iam_policy.terraform_s3_list_read_write_policy.arn,
    aws_iam_user.terraform_ci_user.arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/IAMUserSelfManagement"
    ]
  }
}

resource "aws_iam_policy" "iam_user_self_management_policy" {
  policy = data.aws_iam_policy_document.iam_user_self_management_policy_document.json
  name = "IAMUserSelfManagement"
  path = "/"
  description = "Grants all permissions on terraform-ci user and its IAM policies"
}

# Create IAM user that will be used to update the S3 bucket with terraform state

resource "aws_iam_user" "terraform_ci_user" {
  name = "terraform-ci"
}

resource "aws_iam_policy_attachment" "terraform_s3_list_read_write_policy_attachment" {
  name = "terraform_s3_list_read_write_policy_attachment"
  policy_arn = aws_iam_policy.terraform_s3_list_read_write_policy.arn
  users = [aws_iam_user.terraform_ci_user.name]
}

resource "aws_iam_policy_attachment" "terraform_dynamodb_read_write_policy_attachment" {
  name = "terraform_dynamodb_read_write_policy_attachment"
  users = [aws_iam_user.terraform_ci_user.name]
  policy_arn = aws_iam_policy.terraform_dynamodb_read_write_policy.arn
}

resource "aws_iam_policy_attachment" "iam_user_self_management_policy_attachment" {
  name = "iam_user_self_management_policy_attachment"
  users = [aws_iam_user.terraform_ci_user.name]
  policy_arn = aws_iam_policy.iam_user_self_management_policy.arn
}