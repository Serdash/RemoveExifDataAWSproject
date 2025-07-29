import json
import boto3
import os
import piexif
from PIL import Image

s3 = boto3.client('s3')

def lambda_handler(event, context):
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']

        input_path = f"/tmp/{os.path.basename(object_key)}"
        output_path = f"/tmp/cleaned-{os.path.basename(object_key)}"

        # Download from S3
        s3.download_file(bucket_name, object_key, input_path)

        # Remove EXIF
        image = Image.open(input_path)
        image.save(output_path, "jpeg", exif=piexif.dump({}))

        # Upload to target bucket
        s3.upload_file(output_path, "st-bucket-b", object_key)

        print(f"Uploaded stripped image to st-bucket-b/{object_key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Metadata stripped and uploaded.')
    }
