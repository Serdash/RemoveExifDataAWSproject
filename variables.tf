variable "region" {
  description = "value for AWS region to deploy resources in"
  type        = string
}

variable "bucket_a" {
  description = "name of bucket store pre exif jpg"
  type        = string
}

variable "bucket_b" {
  description = "name of bucket store prepost exif jpg"
  type        = string
}
variable "buckets" {
  description = "all bucket names"
  type        = list(string)
}
variable "users" {
  description = "List of IAM users to create"
  type        = list(string)
}
variable "groups" {
  description = "the list of IAM groups to create"
  type        = map(string)
}
variable "group_membership" {
  description = "the list of IAM users and their corresponding groups"
  type        = map(string)
}
