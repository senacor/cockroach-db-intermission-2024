module "region_eu_central_1"{
  source = "../modules/cockroachDB"

  providers = {
    aws = aws.eu_central
  }
  number_of_available_zones = 2
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtaFRD4B0msUAN4z6Qc0OKv8zI3sLpFgZbCbj0DU7FK ngocson@DESKTOP-8NHE3C2"
}

module "region_eu_west_1"{
  source = "../modules/cockroachDB"

  providers = {
     aws = aws.eu_west_1
   }
  number_of_available_zones = 1
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtaFRD4B0msUAN4z6Qc0OKv8zI3sLpFgZbCbj0DU7FK ngocson@DESKTOP-8NHE3C2"
}