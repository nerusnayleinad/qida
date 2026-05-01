terraform {
  backend "s3" {
    bucket         = "terraform-qida"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    use_lockfile   = true
    encrypt        = true
  }
}