module "region" {
  source = "./modules/cockroachDB"

  region = "eu-central-1"
  number_of_available_zones = 1
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtaFRD4B0msUAN4z6Qc0OKv8zI3sLpFgZbCbj0DU7FK ngocson@DESKTOP-8NHE3C2"
}