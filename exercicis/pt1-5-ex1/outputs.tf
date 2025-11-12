## Instàncies EC2 Outputs

output "public_instance_details" {
  value = {
    for instance in aws_instance.public :
    instance.tags.Name => {
      id        = instance.id
      public_ip = instance.public_ip
      private_ip = instance.private_ip
    }
  }
}

output "private_instance_details" {
  value = {
    for instance in aws_instance.private :
    instance.tags.Name => {
      id        = instance.id
      private_ip = instance.private_ip
    }
  }
}

## Bucket S3 Output

output "s3_bucket_name" {
  value = var.create_s3_bucket ? aws_s3_bucket.conditional_bucket[0].bucket : "Bucket S3 no creat (create_s3_bucket = false)"
}