terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "kafka/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}