# terraform {
#   cloud {

#     organization = "mtc-tf-2024"

#     workspaces {
#       name = "ecs"
#     }
#   }
# }

terraform {
  backend "s3" {
    bucket       = "ai-deployemnts-ajay"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

