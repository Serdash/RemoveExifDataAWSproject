output "bucket_a_name" {
  description = "Name of the source S3 bucket (Bucket A)"
  value       = aws_s3_bucket.Bucket_A.bucket
}

output "bucket_b_name" {
  description = "Name of the destination S3 bucket (Bucket B)"
  value       = aws_s3_bucket.Bucket_B.bucket
}

output "lambda_function_name" {
  description = "Name of the Lambda function used to remove EXIF data"
  value       = aws_lambda_function.remove_exif_jpg.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.remove_exif_jpg.arn
}

output "lambda_execution_role_name" {
  description = "IAM Role name that Lambda function assumes"
  value       = aws_iam_role.remove_exif_jpg.name
}
