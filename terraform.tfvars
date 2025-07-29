#always quote variables 
region   = "eu-west-1"
bucket_a = "st-bucket-a"
bucket_b = "st-bucket-b"
users    = ["Jim", "Dwight"]
buckets  = ["st-bucket_a", "st-bucket_b"]

/*group related variables*/
groups = {
  "s3_R_W"       = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  "s3_Read_Only" = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
group_membership = {
  "Jim"    = "s3_R_W"
  "Dwight" = "s3_Read_Only"
}
