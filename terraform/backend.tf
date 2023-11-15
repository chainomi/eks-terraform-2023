terraform {
  backend "s3" {

    # Choose a suitable key e.g. use <env>/terraform-state as value for key
    key = "dev/terraform.state"
    # Update region
    region = "us-west-1"

  }
}