# gel-platform-engineer-task - Serdash Turna


This project sets up an automated pipeline to process `.jpg` images uploaded to an S3 bucket. The system removes any **EXIF metadata** and stores the cleaned images in a second S3 bucket.

Infrastructure is provisioned using **Terraform**, and the image processing logic runs in an **AWS Lambda function written in Python**.


# Architecture Overview:

User (Jim) or admin -> Uploads .jpg -> S3 Bucket A (st-bucket-a) -> S3 Event Trigger -> AWS Lambda (pyExifRemover.py) ->exifRemovedJPG -> S3 Bucket B (st-bucket-b)


#Prerequisites

Before you begin, make sure you have the following installed:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) **v1.12.2**
- [Python](https://www.python.org/downloads/) **v3.9+**
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) **v2**

# AWS Account setup - You will need access to an AWS account with sufficient permissions to:

Upload `.jpg` files to `st-bucket-a` 


Option 1: Admin Access  
If you have an AWS user with **admin access**, configure it with:

```bash
aws configure
```

Option 2: Use `jim` User  
If using the `jim` IAM user, request the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, then configure:

```bash
aws configure --profile jim
```

You can test uploading a `.jpg` to trigger the Lambda:

```bash
aws s3 cp sample.jpg s3://st-bucket-a/ --profile jim
```

# Deploying the Infrastructure

Use the following commands from the root of this project:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```
