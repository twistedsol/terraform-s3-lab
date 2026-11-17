provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "data" {
  bucket = "twist-demo-data-bucket"
}

resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "public-read"
}
