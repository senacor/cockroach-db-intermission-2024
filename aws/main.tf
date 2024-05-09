module "region" {
  source = "./modules/cockroachDB"

  region = "eu-central-1"
  number_of_available_zones = 1
}