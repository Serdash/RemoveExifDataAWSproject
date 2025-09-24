provider "aws" {
  region = var.region
}
/*Create bucket for terraform tfstate file, will create it after apply*/
terraform {
  backend "s3" {
    bucket       = "s3-terra-state-file"
    key          = "exifRemover/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true

  }
}
/*Create Buckets A and B respectively*/
resource "aws_s3_bucket" "Bucket_A" {
  bucket        = "st-bucket-a"
  force_destroy = true //allows bucket to be deleted even if it has objects in it
  tags = {
    Name = "Bucket A"
  }
}

resource "aws_s3_bucket" "Bucket_B" {
  bucket        = "st-bucket-b"
  force_destroy = true //allows bucket to be deleted even if it has objects in it
  tags = {
    Name = "Bucket B"
  }
}

/*Ensuring the buckets are not publicly accessible*/
resource "aws_s3_bucket_public_access_block" "bucket_a_block" {
  bucket = aws_s3_bucket.Bucket_A.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bucket_b_block" {
  bucket = aws_s3_bucket.Bucket_B.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/*Creates both IAM users*/
resource "aws_iam_user" "user_accounts" {
  for_each      = toset(var.users) # converts list to set as only map and set can work with for each
  name          = each.key
  force_destroy = true
}

resource "aws_iam_group" "s3_groups" {
  for_each = var.groups
  name     = each.key
}

resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each   = var.groups
  group      = aws_iam_group.s3_groups[each.key].name
  policy_arn = each.value
}

resource "aws_iam_user_group_membership" "group_members" {
  for_each = var.group_membership
  user     = aws_iam_user.user_accounts[each.key].name
  groups   = [aws_iam_group.s3_groups[each.value].name]
}

/*IAM trust policy, permission document allowing lambda to assume the role of any IAM role I create
by passing it through the IAM role i create under the assume_role_policy attribute*/
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
/*IAM role created specifying lambda function to assume the role, attaching assume role document 
under assume_role_policy */
resource "aws_iam_role" "remove_exif_jpg" {
  name               = "remove-exif-jpg-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

/*Create the lambda function*/
resource "aws_lambda_function" "remove_exif_jpg" {
  function_name = "remove-exif-jpg-function"
  handler       = "pyExifRemover.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.remove_exif_jpg.arn #assuming the IAM role created above
  filename      = "lambda/lambda_function.zip"

  source_code_hash = filebase64sha256("lambda/lambda_function.zip")

  timeout     = 60  #seconds, max is 900 seconds
  memory_size = 256 #MB, max is 10,240 MB
}

/*adding aws caller identity for policy document, lambda logging resource reference*/
data "aws_caller_identity" "current" {}

/*IAM Policy Document rules and permissions for each bucket for the lambda function role*/
data "aws_iam_policy_document" "lambda_role_policy_permissions" {
  statement {
    sid     = "AllowReadingFromBucketA"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]

    resources = [
      aws_s3_bucket.Bucket_A.arn,       #needed for listing objects in the bucket itself
      "${aws_s3_bucket.Bucket_A.arn}/*" # getting everything inside the bucket as denoted by the /*
    ]
  }
  statement {
    sid     = "AllowWritingToBucketB"
    effect  = "Allow"
    actions = ["s3:putObject", "s3:DeleteObject"]

    resources = ["${aws_s3_bucket.Bucket_B.arn}/*"]
  }
  //adding cloudwatch alarm statment here, for lambda to log
  statement {
    sid     = "AllowCloudWatchLogging"
    effect  = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]

    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.remove_exif_jpg.function_name}:*"]
  }
}

/*Attaching the policy defined in data block lambda_role_policy_permissions to the lambda function */
resource "aws_iam_role_policy" "lambda_policy_attach" {
  name   = "lambda-remove-exif-policy"
  role   = aws_iam_role.remove_exif_jpg.id
  policy = data.aws_iam_policy_document.lambda_role_policy_permissions.json

}

/*allows s3 bucket to notify lambda role to invoke the lambda function*/
resource "aws_lambda_permission" "allowing_s3_to_invoke_lambda" {
  statement_id  = "s3AllowslambdaToInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remove_exif_jpg.arn
  principal     = "s3.amazonaws.com" #service that will call the function
  source_arn    = aws_s3_bucket.Bucket_A.arn
}

/*Create s3 notification so s3 can notify lambda to run its function for it*/
resource "aws_s3_bucket_notification" "bucket_a_notification" {
  bucket = aws_s3_bucket.Bucket_A.id #best practice to use resource instead of var.bucket_a

  lambda_function {
    lambda_function_arn = aws_lambda_function.remove_exif_jpg.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }
  #create a dependancy to ensure the lambda permission is created before the notification
  #this is because the lambda function needs permission to be invoked by the s3 bucket
  depends_on = [aws_lambda_permission.allowing_s3_to_invoke_lambda]
}
