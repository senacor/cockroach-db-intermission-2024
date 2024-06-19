terraform {
  backend "local" {
    path = "local_terraform_state.tfstate"
  }
}