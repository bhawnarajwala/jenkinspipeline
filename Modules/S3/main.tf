resource "aws_s3_bucket" "b1" {
  bucket = var.aws_s3_bucket
  acl = var.acl

  tags = {
    Name        = "My bucket"
    
  }

versioning {
    enabled = var.enabled
  }

}

# resource "aws_s3_bucket_object" "object" {
#   bucket = aws_s3_bucket.b1.id
#   key    = "key1"
#   source = "D:\\name.txt"
#   etag = filemd5("D:\\name.txt")
# }

