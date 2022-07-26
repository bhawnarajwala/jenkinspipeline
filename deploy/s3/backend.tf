terraform {
  backend "s3" {
    bucket = "mytfstatebucketbhawna24"
    key    = "state/terraform.tfstate"
    region = "us-west-2"
  }
}